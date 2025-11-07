# Black-Scholes Greek Validator (AWS)

This project implements a web application to display Black-Scholes Greek validation results. It consists of a static frontend (hosted on AWS S3) and a containerized backend (hosted on AWS App Runner).

The backend is a wrapper that, on startup, runs a C++ program to generate .csv data files and a Python script to generate .png plot files. The API then serves these static files to the frontend.

This project is deployed entirely using Terraform.

Great guide for how to structure a Terraform project can be found [here.](https://spacelift.io/blog/terraform-files)

## Architecture

* **Frontend: A static HTML, Tailwind CSS, and JavaScript file.**

* **Hosted on AWS S3 (configured for static website hosting).**

* **Backend: A Python FastAPI application, containerized with Docker.**

* **Hosted on AWS App Runner (serverless).**

The container build includes g++, make, Python, the C++ source code.

On start, `run_script.sh` compiles and runs the C++/Python logic to generate files, then starts the API server to serve them.

Container Registry: AWS ECR (Elastic Container Registry) stores the backend Docker image.

IaC: Terraform provisions all required cloud resources and permissions.

## Prerequisites

* AWS Account: An AWS account with billing enabled and fully activated (you may encounter issues with a newly created AWS account related to account verification etc.).

* AWS CLI: The AWS Command Line Interface.

* Terraform: The Infrastructure as Code tool.

* Docker: The containerization platform.

## Setup & Authentication

### Configure AWS CLI:
```bash
aws configure
```

(Enter your AWS Access Key ID, Secret Access Key, and default region (e.g. us-east-1 or eu-west 1)).

### Deployment Steps

* Navigate to the terraform directory:
```bash
cd terraform
```

* Initialize Terraform:
```bash
terraform init
```

* Apply Terraform (First Pass): This creates the ECR repository and S3 bucket. Use --target to bypass the aws_apprunner_service, which would fail validation because the Docker image doesn't exist yet.

```bash
terraform apply \
-target=aws_ecr_repository.backend_repo \
-target=aws_s3_bucket.frontnend_bucket \
-target=aws_s3_bucket_website_configuration.frontend_bucket_config \
-target=aws_s3_bucket_public_access_block.frontend_bucket_pab \
-target=aws_s3_bucket_policy.frontend_bucket_policy
```
* You will be prompted for the docker_image_url. You can enter a placeholder for now (e.g., temp).

* Type `yes` to approve the plan.

* Note the docker_repository_url from the output.

**Build & Push Docker Image:**

* Navigate to the `backend` directory.

* Set environment variables for your convenience (replace `eu-west-1` if you want to use a different region):
```bash
cd ../backend
export AWS_REGION=eu-west-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export DOCKER_REPO_URL=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/bs-validator-backend-repo
```

* Authenticate Docker with ECR:
```bash
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

* Build the image:
```bash
docker build -t $DOCKER_REPO_URL:latest .
```

* Push the image:
```bash
docker push $DOCKER_REPO_URL:latest
```

**Apply Terraform (Second Pass)**:

* Navigate back to the `terraform` directory.

* Run `terraform apply` again. This time without any `--target` flags. Terraform will see the ECR/S3 resources already exist and will now create the App Runner service.
```bash
cd ../terraform
terraform apply
```
* When prompted for `docker_image.url`, paste the full URL of the image you just pushed (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/bs-validator-backend-repo:latest)

* Type `yes` to approve.

**Test & Final cpnfiguration**:

* Terraform will output a `backend_url` and `frontend_url`, copy the `backend_url` to your clipboard.

You can then run the `sed` command to replace the `API_URL` in `bs_project.html`.
```bash
sed -i 's|const API_URL = ".*"|const API_URL = "YOUR_BACKEND_URL_HERE"|' ../bs_project.html
```

* Or go to `bs_project.html` and update the `API_URL` constant at the top of the `<script>` tag to the `backend_url`.

* Run `terraform apply` one last time. Terraform will detect the change to `bs_project.html` (via its etag) and re-upload it to S3.

* Open the `frontend_url` in your browser.

## Destroying the Infrastructure

To tear down all created resources and avoid further charges:

1. **Empty S3 Bucket**: AWS requires S3 buckets to be empty before deletion. Go to the AWS S3 console, find your bucket (e.g., `bs-validator-frontend-bucket-...`), and delete the `frontend.html` file.

2. **Empty ECR Repository**: Go to the ECR console, find your `bs-validator-backend-repo`, and delete the image(s) inside it.

3. Run Terraform Destroy:
```bash
cd terraform
terraform destroy
```

## Missing Parts & Non-Idealities

**Manual Deployment Flow**: The flow requires a manual docker build and push between two `terraform apply` runs. The first apply run must use `--target` flags to bypass App Runner's image URL validation. This is somewhat tedious, and could be automated with an AWS CodePipeline or by making the `aws_apprunner_service` resource conditional (e.g., with a count variable).

**Hardcoded API URL**: The `bs_project.html` file has a placeholder `API_URL` that must be manually updated after the first deployment.

**Startup Inefficiency**: The C++ and Python scripts run every time a new container starts. This is simple but inefficient. A better (but more complex) approach would be to run these scripts during the `docker build` process (using `RUN ./run_script.sh`) and have the `CMD` only start the uvicorn server.

**Manual Deletion of S3/ECR Objects**: The destroy process requires you to manually empty the S3 bucket and ECR repository. This is a **deliberate safety measure**, not an oversight. Terraform defaults to `force_destroy = false` on S3 buckets to prevent accidental deletion of production data. Requiring the user to manually delete the files inside the bucket acts as final safeguard against irreversible loss of data. 


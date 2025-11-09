# Black-Scholes Greek Validator (AWS)

This project implements a web application to display Black-Scholes Greek validation results. It consists of a static frontend (hosted on AWS S3) and a containerized backend (hosted on AWS Lambda with an API Gateway).

The backend is a containerized Python FastAPI application. To make sure there are no timeout related issues and to ensure fast startup, the `Dockerfile` pre-compiles the C++ program and runs the Python plotter script during image building phase. The Lambda then only serves these pre-generated files from the container's file system. 

This project is deployed entirely using Terraform.

Great guide for how to structure a Terraform project can be found [here.](https://spacelift.io/blog/terraform-files)

## Architecture

* **Frontend**: A static HTML, Tailwind CSS, and JavaScript file.

* **Hosted on AWS S3** (configured for static website hosting).

* **Backend**: A Python FastAPI application, containerized with Docker.

* **Hosted on AWS Lambda** (serverless).

* **Container Registry**: AWS ECR (Elastic Container Registry) stores the Docker image.

* **IaC**: Terraform provisions all required cloud resources and permissions.

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

(Enter your AWS Access Key ID, Secret Access Key, and default region (e.g. us-east-1 or eu-west 1). This region must match the `region` variable in `terraform/variables.tf`).

### Deployment Steps

This is a 2-pass deployment. The Lambda function cannot be created until the Docker image exists, and the Docker image cannot be pushed until the ECR repository exists.

* Navigate to the terraform directory:
```bash
cd terraform
```

* Initialize Terraform:
```bash
terraform init
```

* Apply Terraform (First Pass): This creates the ECR repository, IAM Role and S3 bucket.

```bash
terraform apply
```
* You will be prompted for the `docker_image_url`. You can enter a placeholder value (e.g., temp).

* Type `yes` to approve the plan.

* Note the `docker_repository_url` from the output.

**Build & Push Docker Image:**

* Navigate to the `backend` directory.

* Set environment variables for your convenience (replace `us-east-1` if you want to use a different region):
```bash
cd ../backend
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export DOCKER_REPO_URL=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/bs-validator-backend-repo
```

* Authenticate Docker with ECR:
```bash
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

* Build the image: (I am using `DOCKER_BUILDKIT=0` here to avoid image manifest issues with AWS Lambda)
```bash
DOCKER_BUILDKIT=0 docker build --no-cache -t $DOCKER_REPO_URL:latest .
```

* Push the image:
```bash
docker push $DOCKER_REPO_URL:latest
```

**Apply Terraform (Second Pass)**:

* Navigate back to the `terraform` directory.
* Run `terraform apply` again.cd
```bash
cd ../terraform
terraform apply
```
* When prompted for `docker_image.url`, paste the full URL of the image you just pushed (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/bs-validator-backend-repo:latest)

* Type `yes` to approve.

**Test & Final cpnfiguration**:

* Terraform will output a `backend_url` and `frontend_url`, copy the `backend_url`.

* Copy the `backend_url`, but be careful to omit the forward slash at the end of the URL.  

You can then run the `sed` command to replace the `API_URL` in `bs_project.html` (paste your `backend_url` into the command).
```bash
sed -i "s|const API_URL = '.*'|const API_URL = '<PASTE-HERE>'|" ../frontend/bs_project.html
```

* Or go to `bs_project.html` and update the `API_URL` constant at the top of the `<script>` tag to the `backend_url`.

* Run `terraform apply` one last time. Terraform will detect the change to `bs_project.html` (via its etag) and re-upload it to S3.

* When prompted paste the `docker_image.url`, and approve the plan by typing `yes`.

* Open the `frontend_url` in your browser.

## Destroying the Infrastructure

* To tear down all created resources and avoid further charges:

Run Terraform Destroy:
```bash
cd terraform
terraform destroy
```
* You will be prompted for the `docker_image.url`, enter it and then when prompted again type `yes` to approve the plan to destroy the resaources.

* If you wish to also remove the terraform state and config files. Navigate to the project root. And from there:
```bash
./remove_terraform.sh
```
* You can then remove the Docker image using the shell script `docker_cleanup.sh`, from the project root:
```bash
./docker_cleanup.sh
```


## Missing Parts & Non-Idealities

**Manual Deployment Flow**: The flow requires a manual docker build and push between two `terraform apply` runs. This is necessary because the Lambda resource depends on an image URL that doesn't exist on the first pass. This could be automated with an AWS CodePipeline.

**Hardcoded API URL**: The `frontend/bs_project.html` file has a placeholder `API_URL` that must be manually updated after the first deployment.

* **Efficient Backend**: This architecture is highly efficient. By running the C++/Python scripts during the docker build phase, the Lambda function has an instantaneous "cold start" and only serves static files, making it very fast and cost-effective.
Black-Scholes Greek Validator (AWS)

This project implements a web application to display Black-Scholes Greek validation results. It consists of a static frontend (hosted on AWS S3) and a containerized backend (hosted on AWS App Runner).

The backend is a wrapper that, on startup, runs a C++ program to generate .csv data files and a Python script to generate .png plot files. The API then serves these static files to the frontend.

This project is deployed entirely using Terraform.

Architecture

Frontend: A static HTML, Tailwind CSS, and JavaScript file.

Hosted on AWS S3 (configured for static website hosting).

Backend: A Python FastAPI application, containerized with Docker.

Hosted on AWS App Runner (serverless).

The container build includes g++, make, Python, the C++ source (main.cpp, bs_greeks.hpp), and the Python plotter (script/plot_results.py).

On start, a script (run_scripts.sh) compiles and runs the C++/Python logic to generate files, then starts the API server to serve them.

Container Registry: AWS ECR (Elastic Container Registry) stores the backend Docker image.

IaC: Terraform provisions all required cloud resources and permissions.

Prerequisites

AWS Account: An AWS account with billing enabled.

AWS CLI: The AWS Command Line Interface.

Terraform: The Infrastructure as Code tool.

Docker: The containerization platform.

C++ Code: You must have your real bs_greeks.hpp file. A mock file is provided so the project can build, but it will not produce correct calculations.

Setup & Authentication

Configure AWS CLI:

aws configure


(Enter your
AWS Access Key ID, Secret Access Key, and default region).

Place Your Code:

Place your real bs_greeks.hpp file into the backend/ directory, replacing the mock file.

Deployment Steps

Navigate to the terraform directory:

cd terraform


Initialize Terraform:

terraform init


Apply Terraform (First Pass): This creates the ECR repository and S3 bucket.

You will be prompted for the docker_image_url. You can enter a placeholder for now (e.g., temp).

terraform apply


Note the docker_repository_url from the output.

Build & Push Docker Image:

Navigate to the backend directory.

Set environment variables for your convenience (replace values):

cd ../backend
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export DOCKER_REPO_URL=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}[.amazonaws.com/bs-validator-backend-repo](https://.amazonaws.com/bs-validator-backend-repo)


Authenticate Docker with ECR:

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com


Build the image:

docker build -t $DOCKER_REPO_URL:latest .


Push the image:

docker push $DOCKER_REPO_URL:latest


Apply Terraform (Second Pass):

Navigate back to the terraform directory.

Run terraform apply again. This time, when prompted for docker_image_url, paste the full URL of the image you just pushed (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com/bs-validator-backend-repo:latest).

cd ../terraform
terraform apply


Test:

Terraform will output a backend_url and frontend_url.

Go to frontend.html and update the API_URL constant at the top of the <script> tag to the backend_url.

Run terraform apply one last time. Terraform will detect the change to frontend.html (via its etag) and re-upload it to S3.

Open the frontend_url in your browser.

Destroying the Infrastructure

To tear down all created resources and avoid further charges:

Empty S3 Bucket: AWS requires S3 buckets to be empty before deletion. Go to the AWS S3 console, find your bucket (e.g., bs-validator-frontend-bucket-...), and delete the frontend.html file.

Empty ECR Repository: Go to the ECR console, find your bs-validator-backend-repo, and delete the image(s) inside it.

Run Terraform Destroy:

cd terraform
terraform destroy


Missing Parts & Non-Idealities

Mock bs_greeks.hpp: The provided bs_greeks.hpp is a mock. You must insert your real file for correct calculations.

Manual Docker Push: The flow requires a manual docker build and push between two terraform apply runs. This could be automated with an AWS CodePipeline.

Hardcoded API URL: The frontend.html file has a placeholder API_URL that must be manually updated after the first deployment.

Startup Inefficiency: The C++ and Python scripts run every time a new container starts. This is simple but inefficient. A better (but more complex) approach would be to run these scripts during the docker build process (using RUN ./run_scripts.sh) and have the CMD only start the uvicorn server.
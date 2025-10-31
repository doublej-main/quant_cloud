variable "region" {
  type        = string
  description = "The AWS region to deploy resources into (e.g., 'us-east-1')."
  default     = "eu-north-1"
}

variable "app_name" {
  type        = string
  description = "A unique name for the application (e.g., 'bs-validator')."
  default     = "bs-validator"
}

variable "docker_image_url" {
  type        = string
  description = "The full URL of the Docker image in ECR. (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com/bs-validator-backend-repo:latest)"
  # No default, user will be prompted.
}

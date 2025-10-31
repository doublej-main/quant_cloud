output "frontend_url" {
  description = "The public URL for the frontend S3 website."
  value       = "http://${aws_s3_bucket_website_configuration.frontend_website.website_endpoint}"
}

output "backend_url" {
  description = "The public URL for the backend App Runner service."
  value       = "https.${aws_apprunner_service.backend_service.service_url}"
}

output "docker_repository_url" {
  description = "The URL of the Docker ECR repository to push images to."
  value       = aws_ecr_repository.backend_repo.repository_url
}

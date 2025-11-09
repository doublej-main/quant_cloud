# terraform/outputs.tf

output "frontend_url" {
  description = "The public URL for the frontend S3 website."
  value       = "http://${aws_s3_bucket_website_configuration.frontend_website.website_endpoint}"
}

output "backend_url" {
  description = "The public URL for the backend API Gateway."
  # Use a conditional to avoid an error on the first pass
  value       = var.docker_image_url == "temp" ? "N/A (created on second pass)" : aws_apigatewayv2_stage.lambda_stage[0].invoke_url
}

output "docker_repository_url" {
  description = "The URL of the Docker ECR repository to push images to."
  value       = aws_ecr_repository.backend_repo.repository_url
}
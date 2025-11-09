# terraform/main.tf

# --- S3 Bucket (Frontend Hosting) ---
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "${var.app_name}-frontend-bucket-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "bs_project.html"
  }
}

# --- S3 Public Access Block & Policy ---
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*"
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.public_access]
}

# --- Upload Frontend File to S3 ---
resource "aws_s3_object" "frontend_html" {
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = "bs_project.html"
  source       = "../frontend/bs_project.html" # Assumes terraform is run from 'terraform/' dir
  content_type = "text/html"
  
  # Force new upload on content change
  etag = filemd5("../frontend/bs_project.html")
}

# --- ECR Repository (Backend Image) ---
resource "aws_ecr_repository" "backend_repo" {
  name                 = "${var.app_name}-backend-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Auto-deletes images on destroy

  image_scanning_configuration {
    scan_on_push = true
  }
}

# --- IAM Role for Lambda ---
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.app_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Policy for Lambda to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy for Lambda to read from ECR
resource "aws_iam_role_policy_attachment" "lambda_ecr" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# --- Lambda Function ---
resource "aws_lambda_function" "backend_lambda" {
  # Only create this on the 2nd pass when docker_image_url is not "temp"
  count = var.docker_image_url == "temp" ? 0 : 1

  function_name = "${var.app_name}-backend-lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  package_type  = "Image"
  image_uri     = var.docker_image_url
  timeout       = 30
  memory_size   = 512
  kms_key_arn   = null
}

# --- API Gateway (HTTP API) ---
resource "aws_apigatewayv2_api" "lambda_api" {
  # Only create this on the 2nd pass
  count = var.docker_image_url == "temp" ? 0 : 1

  name          = "${var.app_name}-backend-api"
  protocol_type = "HTTP"
  
  # Add CORS configuration for the API
  cors_configuration {
    allow_methods = ["*"]
    allow_origins = ["*"] # Allows all origins
    allow_headers = ["*"]
  }
}

# Integration between API Gateway and Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  # Only create this on the 2nd pass
  count = var.docker_image_url == "temp" ? 0 : 1

  api_id           = aws_apigatewayv2_api.lambda_api[0].id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.backend_lambda[0].invoke_arn
}

# Catch-all route for all requests
resource "aws_apigatewayv2_route" "api_route" {
  # Only create this on the 2nd pass
  count = var.docker_image_url == "temp" ? 0 : 1

  api_id    = aws_apigatewayv2_api.lambda_api[0].id
  route_key = "$default" # Catches all paths and methods
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration[0].id}"
}

# Live deployment stage
resource "aws_apigatewayv2_stage" "lambda_stage" {
  # Only create this on the 2nd pass
  count = var.docker_image_url == "temp" ? 0 : 1

  api_id      = aws_apigatewayv2_api.lambda_api[0].id
  name        = "$default"
  auto_deploy = true
}

# Permission for API Gateway to invoke the Lambda
resource "aws_lambda_permission" "api_gateway_permission" {
  # Only create this on the 2nd pass
  count = var.docker_image_url == "temp" ? 0 : 1

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend_lambda[0].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda_api[0].execution_arn}/*/*"
}
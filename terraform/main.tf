# main.tf
# --- S3 Bucket (Frontend Hosting) ---
resource "aws_s3_bucket" "frontend_bucket" {
  # Bucket names must be globally unique
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
  error_document {
    key = "bs_project.html"
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
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# --- IAM Role for App Runner ---
resource "aws_iam_role" "apprunner_ecr_role" {
  name = "${var.app_name}-apprunner-ecr-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_policy" {
  role       = aws_iam_role.apprunner_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# --- App Runner Service (Backend) ---
resource "aws_apprunner_service" "backend_service" {
  service_name = "${var.app_name}-backend-service"

  source_configuration {
    image_repository {
      image_identifier      = var.docker_image_url
      image_repository_type = "ECR"
      image_configuration {
        port = "8000" # Must match Dockerfile/script port
      }
    }
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_role.arn
    }
  }

  network_configuration {
    egress_configuration {
      egress_type = "DEFAULT"
    }
    ingress_configuration {
      is_publicly_accessible = true
    }
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/" # Check the root endpoint of the FastAPI app
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 2
  }

  depends_on = [aws_ecr_repository.backend_repo]
}


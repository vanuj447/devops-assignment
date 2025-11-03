terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# S3 bucket for media storage
resource "aws_s3_bucket" "media_bucket" {
  bucket = "media-streaming-bucket-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Enable versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "media_bucket_versioning" {
  bucket = aws_s3_bucket.media_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CloudFront distribution for content delivery
resource "aws_cloudfront_distribution" "media_distribution" {
  origin {
    domain_name = aws_s3_bucket.media_bucket.bucket_regional_domain_name
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# CloudFront OAI
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for media streaming"
}

# Lambda function for video processing
resource "aws_lambda_function" "video_processor" {
  filename      = "lambda/video_processor.zip"
  function_name = "video-processor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "video_processor.handler"
  runtime       = "nodejs18.x"

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.media_bucket.id
    }
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "video_processor_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# API Gateway
resource "aws_api_gateway_rest_api" "media_api" {
  name = "media-streaming-api"
}

# API Gateway resource
resource "aws_api_gateway_resource" "media" {
  rest_api_id = aws_api_gateway_rest_api.media_api.id
  parent_id   = aws_api_gateway_rest_api.media_api.root_resource_id
  path_part   = "media"
}

# API Gateway method
resource "aws_api_gateway_method" "get_media" {
  rest_api_id   = aws_api_gateway_rest_api.media_api.id
  resource_id   = aws_api_gateway_resource.media.id
  http_method   = "GET"
  authorization = "NONE"
}

# CloudWatch for monitoring
resource "aws_cloudwatch_dashboard" "media_dashboard" {
  dashboard_name = "media-streaming-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "Region", "Global"]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          title  = "CloudFront Requests"
        }
      }
    ]
  })
}

# Output values
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.media_distribution.domain_name
}

output "api_gateway_url" {
  value = aws_api_gateway_rest_api.media_api.execution_arn
}
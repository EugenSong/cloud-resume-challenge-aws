variable "region" { default = "us-east-1" }

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Local Vars (content type)
locals {
  content_types = {
    ".html" = "text/html",
    ".css"  = "text/css",
    ".js"   = "application/javascript",
    ".ico"  = "image/x-icon"
  }
  s3_origin_id = "my-s3-terraform-bucket12359.s3.us-east-1.amazonaws.com"
}

# ===============================
# S3 Bucket Config
# ===============================

# S3 Bucket Creation
resource "aws_s3_bucket" "resume_bucket" {
  bucket = "my-s3-terraform-bucket12359"
  tags   = {
    Name = "Test bucket"
  }
}

# S3 Bucket Public Access
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.resume_bucket.id
  block_public_acls         = false
  block_public_policy       = false
  ignore_public_acls        = false
  restrict_public_buckets   = false
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.resume_bucket.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::my-s3-terraform-bucket12359/*"
      }
    ]
  })
}

# S3 Bucket Objects Insertion
resource "aws_s3_object" "objects" {

  depends_on = [aws_s3_bucket.resume_bucket]
  
  for_each = fileset(".", "*.{html,css,js,ico}")

  bucket = "my-s3-terraform-bucket12359"
  key    = each.value
  source = each.value
  etag   = filemd5(each.value)
  content_type = lookup(local.content_types, lower(regex("\\.[^.]+$", each.value)), "application/octet-stream")
}


# ===============================
# CloudFront Config
# ===============================

resource "aws_cloudfront_distribution" "resume_s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.resume_bucket.bucket_regional_domain_name
    # origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "resume cloudfront distro"
  default_root_object = "Eugene_Song_resume.html"

  # logging_config {
  #   include_cookies = false
  #   bucket          = "mylogs.s3.amazonaws.com"
  #   prefix          = "myprefix"
  # }

  # CNAME
  aliases = ["songeugene.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  price_class = "PriceClass_200"

  # only users from these Whitelisted countries can access
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

# SSL/TLS Certificate (uses ACM-assigned cert)
  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:415316982996:certificate/b29641cf-d004-4915-8a05-33960b691e0b"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}


# ===============================
# DynamoDB Table Config
# ===============================

resource "aws_dynamodb_table" "resume-visitor-dynamodb-table" {
  name           = "VisitorCountsTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "PageID"

  attribute {
    name = "PageID"
    type = "S"
  }

  ### DO NOT NEED TO DECLARE ALL ATTRIBUTES.. EXCLUDE THOSE WHICH DONT NEED INDEXING... JUST THE KEY ONES
  # attribute {
  #   name = "VisitCount"
  #   type = "N"
  # }

   tags = {
    Name        = "cloud-resume-dynamodb"
    Environment = "production"
  }
  ## No need for Auto-Scaling due to minimal traffic
}


# ===============================
# Lambda Config
# ===============================


# Lambda functions need to be packaged - data archive file



# Lambda function
resource "aws_lambda_function" "lambda" {
	# ...


}




# ===============================
# API Gateway Config - HTTP API
# ===============================


# Provision API Gateway - HTTP
resource "aws_apigatewayv2_api" "ResumeAPI-lambda" {
  name          = "visitorcount-lambda-http-api"
  protocol_type = "HTTP"
  cors_configuration  = { 
    allow_origins = 
    allow_methods = 
  }
  target        = aws_lambda_function.lambda.arn

  description = "API for AWS Resume Challenge"
    
}

# Permission
resource "aws_lambda_permission" "apigw" {
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda.arn
    principal     = "apigateway.amazonaws.com"

    source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}




# ===============================
# Example how to gen Random ID ... use random_id resource
# ===============================

# resource "random_id" "id" {
# 	byte_length = 8
# }

# resource "aws_apigatewayv2_api" "api" {
# 	name = "api-${random_id.id.hex}"
# 	# ...
# }





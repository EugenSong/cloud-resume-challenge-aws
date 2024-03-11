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

locals {
  content_types = {
    ".html" = "text/html",
    ".css"  = "text/css",
    ".js"   = "application/javascript",
    ".ico"  = "image/x-icon"
  }
}

module "resume_s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket = "my-s3-terraform-bucket11142"
  
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::my-s3-terraform-bucket11142/*"
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = module.resume_s3_bucket.s3_bucket_id

  block_public_acls   = false
  block_public_policy = false
  ignore_public_acls  = false
  restrict_public_buckets = false
}

resource "aws_s3_object" "objects" {

  depends_on = [module.resume_s3_bucket]
  
  for_each = fileset(".", "*.{html,css,js,ico}")

  bucket = "my-s3-terraform-bucket11142"
  key    = each.value
  source = each.value
  etag   = filemd5(each.value)
  content_type = lookup(local.content_types, lower(regex("\\.[^.]+$", each.value)), "application/octet-stream")
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = module.resume_s3_bucket.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::my-s3-terraform-bucket11142/*"
      },
    ]
  })
}

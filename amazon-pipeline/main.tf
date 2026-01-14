terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  prefix  = trimsuffix(var.s3_prefix, "/")
  folders = ["landing", "processed", "failed"]
}

resource "aws_s3_bucket" "landing" {
  bucket        = var.bucket_name
  force_destroy = false
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "landing" {
  bucket = aws_s3_bucket.landing.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "landing" {
  bucket = aws_s3_bucket.landing.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "landing" {
  bucket                  = aws_s3_bucket.landing.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "folders" {
  count                  = length(local.folders)
  bucket                 = aws_s3_bucket.landing.id
  key                    = "${local.prefix}/${local.folders[count.index]}/"
  content                = ""
  server_side_encryption = "AES256"
}

resource "aws_iam_user" "pipeline" {
  count = var.create_pipeline_user ? 1 : 0

  name          = var.pipeline_username
  force_destroy = true
  tags          = merge(var.tags, { Purpose = "spotify-pipeline-s3" })
}

data "aws_iam_policy_document" "pipeline" {
  count = var.create_pipeline_user ? 1 : 0

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.landing.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${local.prefix}/*"]
    }
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = ["${aws_s3_bucket.landing.arn}/${local.prefix}/*"]
  }
}

resource "aws_iam_user_policy" "pipeline" {
  count = var.create_pipeline_user ? 1 : 0

  name   = "${var.pipeline_username}-s3"
  user   = aws_iam_user.pipeline[0].name
  policy = data.aws_iam_policy_document.pipeline[0].json
}

resource "aws_iam_access_key" "pipeline" {
  count = var.create_pipeline_user && var.create_access_key ? 1 : 0

  user = aws_iam_user.pipeline[0].name
}

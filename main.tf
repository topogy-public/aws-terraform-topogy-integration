# Data sources for CUR 2.0 configuration
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# Local values for CUR 2.0 configuration
locals {
  billing_view_arn = var.cur_billing_view_arn != "" ? var.cur_billing_view_arn : "arn:${data.aws_partition.current.partition}:billing::${data.aws_caller_identity.current.account_id}:billingview/primary"

  table_configurations = {
    COST_AND_USAGE_REPORT = {
      BILLING_VIEW_ARN                      = local.billing_view_arn
      INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY = "FALSE"
      INCLUDE_RESOURCES                     = "TRUE"
      INCLUDE_SPLIT_COST_ALLOCATION_DATA    = "FALSE"
      TIME_GRANULARITY                      = "DAILY"
    }
  }
}

# S3 Bucket for Cost and Usage Report (CUR) data export
# This module creates an S3 bucket with the necessary configuration for storing CUR files
resource "aws_s3_bucket" "cur_bucket" {
  bucket = var.bucket_name

  tags = var.tags
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "cur_bucket_versioning" {
  bucket = aws_s3_bucket.cur_bucket.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cur_bucket_encryption" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.cur_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "cur_bucket_pab" {
  bucket = aws_s3_bucket.cur_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy - secure default with user override option
resource "aws_s3_bucket_policy" "cur_bucket_policy" {
  bucket = aws_s3_bucket.cur_bucket.id

  policy = var.bucket_policy != null ? var.bucket_policy : jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid    = "EnableAWSDataExportsToWriteToS3AndCheckPolicy"
        Effect = "Allow"
        Principal = {
          Service = [
            "billingreports.amazonaws.com",
            "bcm-data-exports.amazonaws.com"
          ]
        }
        Action = [
          "s3:PutObject",
          "s3:GetBucketPolicy"
        ]
        Resource = [
          aws_s3_bucket.cur_bucket.arn,
          "${aws_s3_bucket.cur_bucket.arn}/*"
        ]
        Condition = {
          StringLike = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            "aws:SourceArn" = [
              "arn:${data.aws_partition.current.partition}:cur:us-east-1:${data.aws_caller_identity.current.account_id}:definition/*",
              "arn:${data.aws_partition.current.partition}:bcm-data-exports:us-east-1:${data.aws_caller_identity.current.account_id}:export/*"
            ]
          }
        }
      },
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.cur_bucket.arn,
          "${aws_s3_bucket.cur_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ])
  })
}

# S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "cur_bucket_lifecycle" {
  count  = var.enable_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.cur_bucket.id

  rule {
    id     = "cur_lifecycle_rule"
    status = "Enabled"

    filter {
      prefix = "${var.s3_path_prefix}/"
    }

    expiration {
      days = var.lifecycle_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_noncurrent_version_expiration_days
    }
  }
}

# Cost and Usage Report (CUR) 2.0 configuration
resource "aws_bcmdataexports_export" "cur_report" {
  count = var.enable_cur ? 1 : 0

  export {
    name = var.cur_report_name
    data_query {
      query_statement      = var.cur_query_statement
      table_configurations = local.table_configurations
    }

    destination_configurations {
      s3_destination {
        s3_bucket = aws_s3_bucket.cur_bucket.bucket
        s3_prefix = var.s3_path_prefix
        s3_region = aws_s3_bucket.cur_bucket.region
        s3_output_configurations {
          output_type = var.cur_output_type
          format      = var.cur_format
          compression = var.cur_compression
          overwrite   = var.cur_overwrite
        }
      }
    }

    refresh_cadence {
      frequency = var.cur_frequency
    }
  }

  tags = var.tags
}

# IAM policy used to grant the FinTeCrossAccountRole access to the S3 bucket
# which is storing the CUR 2.0 report
resource "aws_iam_policy" "cur_access_policy" {
  count       = var.create_cur_access_policy ? 1 : 0
  name        = var.cur_access_policy_name
  description = "Policy to allow FinTeCrossAccountRole access to the S3 bucket which is storing the CUR 2.0 report"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CurBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.cur_bucket.arn,
          "${aws_s3_bucket.cur_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach the CUR access policy to the existing FinTeCrossAccountRole
resource "aws_iam_role_policy_attachment" "cur_access_policy_attachment" {
  count      = var.create_cur_access_policy ? 1 : 0
  role       = var.cross_account_role_name
  policy_arn = aws_iam_policy.cur_access_policy[0].arn
}

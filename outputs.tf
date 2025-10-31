output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.cur_bucket.id
}

output "s3_path_prefix" {
  description = "The S3 path prefix for organizing CUR files"
  value       = var.s3_path_prefix
}

output "cur_report_name" {
  description = "Name of the Cost and Usage Report 2.0 export"
  value       = var.enable_cur ? aws_bcmdataexports_export.cur_report[0].export[0].name : null
}

output "bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.cur_bucket.region
}

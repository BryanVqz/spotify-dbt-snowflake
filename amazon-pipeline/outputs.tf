output "s3_bucket" {
  description = "Bucket name for the pipeline."
  value       = aws_s3_bucket.landing.bucket
}

output "s3_prefix" {
  description = "Prefix inside the bucket for pipeline files."
  value       = "${local.prefix}/"
}

output "s3_uri_prefix" {
  description = "Convenience S3 URI for the landing prefix."
  value       = "s3://${aws_s3_bucket.landing.bucket}/${local.prefix}/"
}

output "pipeline_user" {
  description = "IAM username (if created)."
  value       = try(aws_iam_user.pipeline[0].name, null)
}

output "pipeline_access_key_id" {
  description = "Access key ID (sensitive, only when create_access_key is true)."
  value       = try(aws_iam_access_key.pipeline[0].id, null)
  sensitive   = true
}

output "pipeline_secret_access_key" {
  description = "Secret access key (sensitive, only when create_access_key is true)."
  value       = try(aws_iam_access_key.pipeline[0].secret, null)
  sensitive   = true
}

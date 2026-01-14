variable "aws_region" {
  type        = string
  description = "AWS region for all resources."
  default     = "us-east-1"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for pipeline landing/processed/failed data."
}

variable "s3_prefix" {
  type        = string
  description = "Base prefix inside the bucket for this project (no trailing slash)."
  default     = "spotify"
}

variable "create_pipeline_user" {
  type        = bool
  description = "Whether to create a dedicated IAM user scoped to the bucket/prefix."
  default     = false
}

variable "create_access_key" {
  type        = bool
  description = "Whether to create an IAM access key for the pipeline user (stored in state)."
  default     = false
}

variable "pipeline_username" {
  type        = string
  description = "IAM username to create when create_pipeline_user is true."
  default     = "spotify-pipeline"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources."
  default = {
    Project   = "spotify-pipeline"
    ManagedBy = "terraform"
  }
}

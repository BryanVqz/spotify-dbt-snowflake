# Terraform for Spotify Pipeline (S3 + IAM)

Simple Terraform stack to create:
- S3 bucket with `landing/`, `processed/`, `failed/` prefixes (versioned, encrypted, public access blocked).
- Optional IAM user scoped to that bucket/prefix, with an access key for the pipeline.

Remote state is recommended so multiple laptops share one state. A helper script is included to create the remote state bucket/table.

## Prereqs (per laptop)
- AWS CLI installed and configured (admin creds): `aws configure --profile spotify-admin` (region `us-east-1`).
- Terraform installed: `brew install terraform`
- Set profile in shell: `export AWS_PROFILE=spotify-admin`
- (Python) In repo root: `python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt`

## One-time backend bootstrap (remote state)
Create an S3 bucket + DynamoDB table for Terraform state/locks:
```bash
cd /Users/bryan.quezadavasquez/Library/CloudStorage/OneDrive-Slalom/Documents/development/dbt/spotify-pipeline/amazon-pipeline
./scripts/bootstrap_backend.sh spotify-terraform-state-bryan terraform-locks-spotify us-east-1
```
Run once; it’s idempotent if the names match.

## Configure backend
Edit `backend.tf` if you use different names. Current defaults:
- Bucket: `spotify-terraform-state-bryan`
- Key: `spotify-pipeline/terraform.tfstate`
- Region: `us-east-1`
- Lock table: `terraform-locks-spotify`

## Init and deploy
```bash
cd amazon-pipeline
terraform init           # will use remote state backend
terraform plan \
  -var="bucket_name=spotify-pipeline-bryan-development" \
  -var="s3_prefix=spotify" \
  -var="aws_region=us-east-1" \
  -var="create_pipeline_user=true" \
  -var="create_access_key=true"

terraform apply \
  -var="bucket_name=spotify-pipeline-bryan-development" \
  -var="s3_prefix=spotify" \
  -var="aws_region=us-east-1" \
  -var="create_pipeline_user=true" \
  -var="create_access_key=true"
```

## Outputs and app env vars
After apply:
```bash
terraform output pipeline_access_key_id
terraform output pipeline_secret_access_key
```
Export for the pipeline code (per machine, not committed):
```bash
export AWS_ACCESS_KEY_ID=<output>
export AWS_SECRET_ACCESS_KEY=<output>
export AWS_DEFAULT_REGION=us-east-1
export S3_BUCKET=spotify-pipeline-bryan-development
export S3_PREFIX=spotify/landing/
```

## Cleanup
To destroy the stack:
```bash
terraform destroy \
  -var="bucket_name=spotify-pipeline-bryan-development" \
  -var="s3_prefix=spotify" \
  -var="aws_region=us-east-1" \
  -var="create_pipeline_user=true" \
  -var="create_access_key=true"
```

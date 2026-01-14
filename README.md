# Spotify Pipeline Skeleton

Starter kit for Snowflake + dbt + AWS S3. One root venv, Python pipeline under `src/`, dbt under `dbt/`, and Terraform infra under `amazon-pipeline/`. Remote Terraform state is already configured for multi-laptop use.

## Layout
- `src/pipeline/generation/`: sample data generators (`generate_people`, `daily_generate_people`) that optionally upload to S3 if `S3_BUCKET` is set.
- `src/pipeline/ingestion/`: Snowflake loader (`load_to_snowflake.py`).
- `src/pipeline/utils/`: helpers (e.g., `s3_upload.py`).
- `dbt/`: dbt project (`dbt_project.yml`, `profiles.yml`, models, macros, tests).
- `amazon-pipeline/`: Terraform for S3 + IAM (uses S3 backend + DynamoDB lock).
- `requirements.txt`: Python deps (dbt, Snowflake connector, boto3).

## Quick start (per laptop)
```bash
cd /Users/bryan.quezadavasquez/Library/CloudStorage/OneDrive-Slalom/Documents/development/dbt/spotify-pipeline
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export PYTHONPATH=src
export AWS_PROFILE=spotify-admin  # uses credentials in ~/.aws/credentials
```
Snowflake env vars required: `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_SCHEMA` (optional `SNOWFLAKE_ROLE`).

## Data generation (local + optional S3 upload)
```bash
# Single file (writes to historical_data/landing/people.csv)
PYTHONPATH=src .venv/bin/python -m pipeline.generation.generate_people --rows 100 --seed 42

# Timestamped daily file (historical_data/landing/people_YYYYMMDD_HHMMSS.csv)
PYTHONPATH=src .venv/bin/python -m pipeline.generation.daily_generate_people --rows 100
```
Set these to also push to S3 after writing:
```
export S3_BUCKET=spotify-pipeline-bryan-development
export S3_PREFIX=spotify/landing/
```

## Load to Snowflake
```bash
PYTHONPATH=src .venv/bin/python -m pipeline.ingestion.load_to_snowflake \
  --csv-path historical_data/landing/people.csv \
  --table PEOPLE \
  --truncate
```

## dbt
```bash
cd dbt
../.venv/bin/dbt debug --profiles-dir .   # verify Snowflake connectivity
../.venv/bin/dbt run --profiles-dir .     # runs models (currently a stub)
```

## Terraform (S3 + IAM with remote state)
Remote state bucket/table were bootstrapped as:
- State bucket: `spotify-terraform-state-bryan`
- Lock table: `terraform-locks-spotify`

Run infra (from `amazon-pipeline/`, using `AWS_PROFILE=spotify-admin`):
```bash
./scripts/bootstrap_backend.sh spotify-terraform-state-bryan terraform-locks-spotify us-east-1
terraform init
terraform apply \
  -var="bucket_name=spotify-pipeline-bryan-development" \
  -var="s3_prefix=spotify" \
  -var="aws_region=us-east-1" \
  -var="create_pipeline_user=true" \
  -var="create_access_key=true"

# Get pipeline creds (export for app use)
terraform output pipeline_access_key_id
terraform output pipeline_secret_access_key
```

## Environment summary
- Python: root `.venv` only; activate before running pipeline/dbt.
- AWS: `AWS_PROFILE=spotify-admin` for Terraform; pipeline uses `AWS_ACCESS_KEY_ID/SECRET/DEFAULT_REGION` (from Terraform outputs) plus `S3_BUCKET/S3_PREFIX`.
- Snowflake: env vars listed above; dbt `profiles.yml` reads them via `env_var`.

## Notes
- Keep data out of git; use S3 for landing/processed/failed.
- Remote Terraform state ensures all laptops share one state; do not delete `spotify-terraform-state-bryan` or `terraform-locks-spotify`.

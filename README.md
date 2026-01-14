# Spotify Pipeline Skeleton

Starter kit for Snowflake + dbt + AWS S3. Everything lives under a single repo with one root venv, dbt project under `dbt/`, Terraform infra under `amazon-pipeline/`, and Snowflake bootstrap SQL under `snowflake/` (to run in a Snowsight worksheet/notebook). Remote Terraform state is already configured for multi-laptop use.

## Layout
- `snowflake/bootstrap.sql`: one-time Snowflake setup (role, warehouse, database, schema, user).
- `dbt/`: dbt project (`dbt_project.yml`, `profiles.yml`, models, macros, tests).
- `amazon-pipeline/`: Terraform for S3 + IAM (uses S3 backend + DynamoDB lock).
- `requirements.txt`: Python deps (dbt, Snowflake connector, boto3).

## Quick start (per laptop)
```bash
cd /Users/bryan.quezadavasquez/Library/CloudStorage/OneDrive-Slalom/Documents/development/dbt/spotify-pipeline
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Snowflake bootstrap (Snowsight)
Open `src/snowflake/bootstrap.sql` in a Snowsight worksheet, replace the placeholder password, and run as `ACCOUNTADMIN`. It will create:
- Role: SPOTIFY_ROLE
- Warehouse: SPOTIFY_WH
- Database: SPOTIFY_ANALYTICS
- Schema: BRONZE
- User: SPOTIFY_USER (change password before running)

## dbt
```bash
cd dbt
../.venv/bin/dbt debug --profiles-dir .   # verify Snowflake connectivity
../.venv/bin/dbt run --profiles-dir .     # runs models (currently a stub)
```
Snowflake env vars required: `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_SCHEMA` (optional `SNOWFLAKE_ROLE`). `profiles.yml` reads them via `env_var`.

## S3 → Snowflake loader
Reads landing files from S3 and writes them into `BRONZE.STREAMING_HISTORY_RAW`, then moves the files to `processed/` or `failed/`.
```bash
source .venv/bin/activate
export AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... AWS_DEFAULT_REGION=us-east-1
export SNOWFLAKE_ACCOUNT=ai74421.us-east-2.aws
export SNOWFLAKE_USER=SPOTIFY_USER
export SNOWFLAKE_PASSWORD=...           # from bootstrap
export SNOWFLAKE_WAREHOUSE=SPOTIFY_WH
export SNOWFLAKE_DATABASE=SPOTIFY_ANALYTICS
export SNOWFLAKE_SCHEMA=BRONZE
python src/s3_to_snowflake_loader.py
```
Optional envs: `S3_BUCKET` (default `spotify-pipeline-bryan-development`), `S3_PREFIX` (default `spotify`), `SNOWFLAKE_ROLE` (default unset).

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

terraform output pipeline_access_key_id
terraform output pipeline_secret_access_key
```

## Environment summary
- Python: root `.venv` only; activate before running dbt.
- AWS: `AWS_PROFILE=spotify-admin` for Terraform; app creds come from Terraform outputs (`AWS_ACCESS_KEY_ID/SECRET/DEFAULT_REGION`, `S3_BUCKET/S3_PREFIX`).
- Snowflake: env vars listed above; bootstrap via `src/snowflake_bootstrap.sql`.

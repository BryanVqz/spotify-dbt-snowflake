"""
Validation script to test S3 and Snowflake connections.
Does NOT load any data - just verifies connectivity and lists files.
"""
import logging
import os
import sys

import boto3
import snowflake.connector

logging.basicConfig(
    level=logging.INFO
)
logger = logging.getLogger(__name__)


def validate_s3_connection():
    """Test S3 connection and list files in landing folder."""
    logger.info("=" * 60)
    logger.info("VALIDATING S3 CONNECTION")
    logger.info("=" * 60)
    
    bucket = os.getenv("S3_BUCKET", "spotify-pipeline-bryan-development")
    prefix = os.getenv("S3_PREFIX", "spotify")
    landing_prefix = f"{prefix}/landing/"
    
    logger.info(f"Bucket: {bucket}")
    logger.info(f"Landing prefix: {landing_prefix}")
    
    try:
        s3_client = boto3.client("s3")
        
        # Test bucket access
        logger.info("Testing bucket access...")
        s3_client.head_bucket(Bucket=bucket)
        logger.info("Bucket access successful")
        
        # List files in landing
        logger.info(f"Listing files in {landing_prefix}...")
        paginator = s3_client.get_paginator("list_objects_v2")
        file_count = 0
        
        for page in paginator.paginate(Bucket=bucket, Prefix=landing_prefix):
            for obj in page.get("Contents", []):
                key = obj["Key"]
                if key.endswith("/"):
                    continue
                file_count += 1
                size_kb = obj["Size"] / 1024
                logger.info(f"  - {key} ({size_kb:.2f} KB)")
        
        if file_count == 0:
            logger.warning("No files found in landing folder")
        else:
            logger.info(f"Found {file_count} file(s) in landing folder")
        
        return True
        
    except Exception as e:
        logger.error(f"S3 connection failed: {e}")
        return False


def validate_snowflake_connection():
    """Test Snowflake connection and verify database/schema."""
    logger.info("")
    logger.info("=" * 60)
    logger.info("VALIDATING SNOWFLAKE CONNECTION")
    logger.info("=" * 60)
    
    # Check required env vars
    required_vars = [
        "SNOWFLAKE_ACCOUNT",
        "SNOWFLAKE_USER",
        "SNOWFLAKE_PASSWORD",
        "SNOWFLAKE_WAREHOUSE",
        "SNOWFLAKE_DATABASE",
        "SNOWFLAKE_SCHEMA",
    ]
    
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    if missing_vars:
        logger.error(f"Missing environment variables: {', '.join(missing_vars)}")
        return False
    
    account = os.environ["SNOWFLAKE_ACCOUNT"]
    user = os.environ["SNOWFLAKE_USER"]
    warehouse = os.environ["SNOWFLAKE_WAREHOUSE"]
    database = os.environ["SNOWFLAKE_DATABASE"]
    schema = os.environ["SNOWFLAKE_SCHEMA"]
    role = os.getenv("SNOWFLAKE_ROLE")
    
    logger.info(f"Account: {account}")
    logger.info(f"User: {user}")
    logger.info(f"Warehouse: {warehouse}")
    logger.info(f"Database: {database}")
    logger.info(f"Schema: {schema}")
    logger.info(f"Role: {role or '(not set)'}")
    
    try:
        logger.info("Connecting to Snowflake...")
        conn = snowflake.connector.connect(
            account=account,
            user=user,
            password=os.environ["SNOWFLAKE_PASSWORD"],
            warehouse=warehouse,
            database=database,
            schema=schema,
            role=role,
        )
        logger.info("Connection successful")
        
        # Test query
        logger.info("Testing query execution...")
        with conn.cursor() as cur:
            cur.execute("SELECT CURRENT_VERSION(), CURRENT_USER(), CURRENT_ROLE(), CURRENT_WAREHOUSE()")
            result = cur.fetchone()
            logger.info(f"Snowflake version: {result[0]}")
            logger.info(f"Current user: {result[1]}")
            logger.info(f"Current role: {result[2]}")
            logger.info(f"Current warehouse: {result[3]}")
        
        # Check if schema exists and is accessible
        logger.info(f"Checking schema {database}.{schema}...")
        with conn.cursor() as cur:
            cur.execute(f"SHOW TABLES IN SCHEMA {database}.{schema}")
            tables = cur.fetchall()
            if tables:
                logger.info(f"Schema exists with {len(tables)} table(s):")
                for table in tables:
                    logger.info(f"  - {table[1]}")  # table name is in column 1
            else:
                logger.info("Schema exists (no tables yet)")
        
        conn.close()
        logger.info("Snowflake validation complete")
        return True
        
    except Exception as e:
        logger.error(f"Snowflake connection failed: {e}")
        return False


def main():
    logger.info("Starting validation...")
    logger.info("")
    
    s3_ok = validate_s3_connection()
    sf_ok = validate_snowflake_connection()
    
    logger.info("")
    logger.info("=" * 60)
    logger.info("VALIDATION SUMMARY")
    logger.info("=" * 60)
    logger.info(f"S3 Connection: {'PASS' if s3_ok else 'FAIL'}")
    logger.info(f"Snowflake Connection: {'PASS' if sf_ok else 'FAIL'}")
    
    if s3_ok and sf_ok:
        logger.info("")
        logger.info("All validations passed! Ready to load data.")
        sys.exit(0)
    else:
        logger.error("")
        logger.error("Some validations failed. Fix issues before loading data.")
        sys.exit(1)


if __name__ == "__main__":
    main()
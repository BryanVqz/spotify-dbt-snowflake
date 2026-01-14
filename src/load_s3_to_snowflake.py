import json
import os
import re
from typing import List, Optional, Tuple

import boto3
import snowflake.connector

TABLE_NAME = "STREAMING_HISTORY_RAW"


def get_snowflake_connection():
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
        database=os.environ["SNOWFLAKE_DATABASE"],
        schema=os.environ["SNOWFLAKE_SCHEMA"],
        role=os.getenv("SNOWFLAKE_ROLE"),
    )


def ensure_table_exists(conn):
    sql = f"""
    CREATE TABLE IF NOT EXISTS {TABLE_NAME} (
        user_id STRING,
        file_name STRING,
        s3_key STRING,
        s3_etag STRING,
        s3_last_modified TIMESTAMP_LTZ,
        consumed_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
        raw VARIANT
    )
    """
    with conn.cursor() as cur:
        cur.execute(sql)


def extract_user_id_from_filename(filename: str) -> Optional[str]:
    match = re.match(r"^(\d+)_", filename)
    return match.group(1) if match else None


def list_landing_files(s3_client, bucket: str, prefix: str) -> List[dict]:
    landing_prefix = f"{prefix}/landing/"
    files = []
    paginator = s3_client.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=bucket, Prefix=landing_prefix):
        for obj in page.get("Contents", []):
            key = obj["Key"]
            if key.endswith("/"):
                continue
            files.append(obj)
    return files


def read_json_from_s3(s3_client, bucket: str, key: str) -> Tuple[List[dict], dict]:
    response = s3_client.get_object(Bucket=bucket, Key=key)
    body = response["Body"].read().decode("utf-8")
    metadata = {
        "etag": response.get("ETag", "").strip('"'),
        "last_modified": response.get("LastModified"),
    }
    parsed_data = json.loads(body)
    return parsed_data, metadata


def insert_records_batch(conn, table_name: str, records: List[Tuple]) -> int:
    if not records:
        return 0
    placeholders = []
    params: List = []
    for row in records:
        placeholders.append("(%s, %s, %s, %s, %s, %s)")
        params.extend(row)
    values_clause = ", ".join(placeholders)
    sql = f"""
    INSERT INTO {table_name} (user_id, file_name, s3_key, s3_etag, s3_last_modified, raw)
    SELECT column1, column2, column3, column4, column5, parse_json(column6)
    FROM VALUES {values_clause}
    """
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.rowcount


def already_loaded(conn, file_name: str, s3_key: str) -> bool:
    sql = f"select 1 from {TABLE_NAME} where file_name = %s and s3_key = %s limit 1"
    with conn.cursor() as cur:
        cur.execute(sql, (file_name, s3_key))
        return cur.fetchone() is not None


def move_object(s3_client, bucket: str, source_key: str, destination_key: str) -> None:
    copy_source = {"Bucket": bucket, "Key": source_key}
    s3_client.copy_object(Bucket=bucket, Key=destination_key, CopySource=copy_source)
    s3_client.delete_object(Bucket=bucket, Key=source_key)


def process_file(s3_client, conn, bucket: str, prefix: str, obj: dict) -> None:
    key = obj["Key"]
    filename = key.split("/")[-1]
    processed_key = f"{prefix}/processed/{filename}"
    failed_key = f"{prefix}/failed/{filename}"

    if not filename.lower().endswith(".json"):
        move_object(s3_client, bucket, key, failed_key)
        print(f"{filename}: skipped (non-JSON) -> failed/")
        return

    try:
        if already_loaded(conn, filename, key):
            move_object(s3_client, bucket, key, processed_key)
            print(f"{filename}: already loaded -> processed/")
            return
        data, metadata = read_json_from_s3(s3_client, bucket, key)
        if not isinstance(data, list):
            raise ValueError("Expected JSON array")
        user_id = extract_user_id_from_filename(filename)
        records = []
        for item in data:
            json_str = json.dumps(item)
            record = (
                user_id,
                filename,
                key,
                metadata["etag"],
                metadata["last_modified"],
                json_str,
            )
            records.append(record)
        # Insert in batches
        batch_size = 1000
        for i in range(0, len(records), batch_size):
            batch = records[i : i + batch_size]
            insert_records_batch(conn, TABLE_NAME, batch)
    except Exception as exc:
        move_object(s3_client, bucket, key, failed_key)
        print(f"{filename}: failed -> failed/ ({exc})")
        return

    move_object(s3_client, bucket, key, processed_key)
    print(f"{filename}: loaded -> processed/")


def main():
    bucket = os.getenv("S3_BUCKET", "spotify-pipeline-bryan-development")
    prefix = os.getenv("S3_PREFIX", "spotify")
    print(f"Bucket: {bucket}")
    print(f"Prefix: {prefix}")
    s3_client = boto3.client("s3")
    conn = get_snowflake_connection()
    ensure_table_exists(conn)
    files = list_landing_files(s3_client, bucket, prefix)
    if not files:
        print("No files found in landing/")
        conn.close()
        return
    for obj in files:
        process_file(s3_client, conn, bucket, prefix, obj)
    conn.close()


if __name__ == "__main__":
    main()

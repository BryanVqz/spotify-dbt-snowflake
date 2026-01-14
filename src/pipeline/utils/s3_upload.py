from __future__ import annotations

import os
from pathlib import Path
from typing import Optional

import boto3
from botocore.exceptions import BotoCoreError, ClientError


def upload_file(path: Path, bucket: str, prefix: str = "landing/") -> str:
    """
    Upload a local file to S3 and return the s3:// URI.
    """
    client = boto3.client("s3")
    key = f"{prefix.rstrip('/')}/{path.name}"
    client.upload_file(str(path), bucket, key)
    return f"s3://{bucket}/{key}"


def maybe_upload_from_env(path: Path) -> Optional[str]:
    """
    Upload if S3_BUCKET is set; prefix defaults to S3_PREFIX or landing/.
    """
    bucket = os.getenv("S3_BUCKET")
    if not bucket:
        return None

    prefix = os.getenv("S3_PREFIX", "landing/")
    try:
        return upload_file(path, bucket=bucket, prefix=prefix)
    except (BotoCoreError, ClientError) as exc:
        raise RuntimeError(f"Failed to upload {path} to s3://{bucket}/{prefix}: {exc}") from exc

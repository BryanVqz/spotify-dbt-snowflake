import argparse
import json
import os
import random
import string
import time
from datetime import datetime, timezone

import boto3


def random_word(length: int = 8) -> str:
    letters = string.ascii_letters
    return "".join(random.choice(letters) for _ in range(length))


def build_rows(count: int):
    rows = []
    for _ in range(count):
        rows.append(
            {
                "ts": datetime.now(timezone.utc).isoformat(),
                "platform": random.choice(["ios", "android", "windows", "mac"]),
                "ms_played": random.randint(0, 120000),
                "conn_country": random.choice(["US", "MX", "CA", "BR", "CO"]),
                "ip_addr": ".".join(str(random.randint(0, 255)) for _ in range(4)),
                "master_metadata_track_name": random_word(10),
                "master_metadata_album_artist_name": random_word(8),
                "master_metadata_album_album_name": random_word(12),
                "spotify_track_uri": f"spotify:track:{random_word(10)}",
                "episode_name": None,
                "episode_show_name": None,
                "spotify_episode_uri": None,
                "audiobook_title": None,
                "audiobook_uri": None,
                "audiobook_chapter_uri": None,
                "audiobook_chapter_title": None,
                "reason_start": random.choice(["clickrow", "fwdbtn", "backbtn", "endplay"]),
                "reason_end": random.choice(["endplay", "trackdone", "unexpected-exit-while-paused"]),
                "shuffle": random.choice([True, False]),
                "skipped": random.choice([True, False]),
                "offline": random.choice([True, False, None]),
                "offline_timestamp": None,
                "incognito_mode": False,
            }
        )
    return rows


def upload_json_to_s3(json_text: str, bucket: str, prefix: str, filename: str) -> str:
    key = f"{prefix}/landing/{filename}"
    s3 = boto3.client("s3")
    s3.put_object(Bucket=bucket, Key=key, Body=json_text)
    return key


def main():
    parser = argparse.ArgumentParser(description="Generate a random JSON array (Spotify-like) and upload to S3 landing/")
    parser.add_argument("--rows", type=int, default=150, help="Number of rows to generate (default 150)")
    parser.add_argument("--user-id", type=str, help="User id prefix for filename; defaults to random 4 digits")
    parser.add_argument("--filename", type=str, help="Optional filename; defaults to <user_id>_Synthetic_History_<ts>.json")
    args = parser.parse_args()

    bucket = os.getenv("S3_BUCKET", "spotify-pipeline-bryan-development")
    prefix = os.getenv("S3_PREFIX", "spotify")

    user_id = args.user_id or f"{random.randint(5, 9):04d}"
    rows = build_rows(args.rows)
    json_text = json.dumps(rows, ensure_ascii=False, indent=2)

    if not args.filename:
        ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        args.filename = f"{user_id}_Synthetic_History_{ts}.json"

    key = upload_json_to_s3(json_text, bucket, prefix, args.filename)
    print(f"Generated {len(rows)} rows for user {user_id}")
    print(f"Uploaded to s3://{bucket}/{key}")


if __name__ == "__main__":
    main()

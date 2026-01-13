#!/usr/bin/env python3
"""
Load the generated people CSV into Snowflake.

Reads a CSV (default: historical_data/landing/people.csv) and inserts rows into
a Snowflake table. Connection details come from environment variables with
optional CLI overrides.

Required env vars (or pass via CLI):
- SNOWFLAKE_ACCOUNT
- SNOWFLAKE_USER
- SNOWFLAKE_PASSWORD
- SNOWFLAKE_WAREHOUSE
- SNOWFLAKE_DATABASE
- SNOWFLAKE_SCHEMA
Optional: SNOWFLAKE_ROLE
"""

import argparse
import csv
import os
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

import snowflake.connector

PROJECT_ROOT = Path(__file__).resolve().parents[3]
LANDING_DIR = PROJECT_ROOT / "historical_data" / "landing"
DEFAULT_CSV = LANDING_DIR / "people.csv"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Load a CSV file into a Snowflake table."
    )
    parser.add_argument(
        "--csv-path",
        type=Path,
        default=DEFAULT_CSV,
        help="Path to the CSV file to load (default: historical_data/landing/people.csv).",
    )
    parser.add_argument(
        "--table",
        default="PEOPLE",
        help="Target table name (default: PEOPLE).",
    )
    parser.add_argument(
        "--database",
        default=None,
        help="Snowflake database name (overrides SNOWFLAKE_DATABASE).",
    )
    parser.add_argument(
        "--schema",
        default=None,
        help="Snowflake schema name (overrides SNOWFLAKE_SCHEMA).",
    )
    parser.add_argument(
        "--warehouse",
        default=None,
        help="Snowflake warehouse (overrides SNOWFLAKE_WAREHOUSE).",
    )
    parser.add_argument(
        "--role",
        default=None,
        help="Snowflake role (overrides SNOWFLAKE_ROLE).",
    )
    parser.add_argument(
        "--truncate",
        action="store_true",
        help="Truncate the table before inserting rows.",
    )
    return parser.parse_args()


def require(value: str, name: str) -> str:
    if not value:
        raise ValueError(f"Missing required connection value: {name}")
    return value


def safe_ident(name: str) -> str:
    cleaned = name.strip().replace("\"", "")
    if not cleaned.replace("_", "").isalnum():
        raise ValueError(f"Invalid identifier: {name}")
    return cleaned


def quoted(name: str) -> str:
    return f'"{safe_ident(name)}"'


def load_rows(csv_path: Path) -> List[Tuple[int, str, str, str, int]]:
    if not csv_path.exists():
        raise FileNotFoundError(f"CSV not found: {csv_path}")

    with csv_path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        expected = {"ID", "First Name", "Last Name", "Role", "Age"}
        if set(reader.fieldnames or []) != expected:
            missing = expected - set(reader.fieldnames or [])
            raise ValueError(f"CSV missing expected columns: {', '.join(sorted(missing))}")

        rows = []
        for row in reader:
            rows.append(
                (
                    int(row["ID"]),
                    row["First Name"],
                    row["Last Name"],
                    row["Role"],
                    int(row["Age"]),
                )
            )
    return rows


def create_table(cursor, database: str, schema: str, table: str) -> None:
    ddl = f"""
    create table if not exists {quoted(database)}.{quoted(schema)}.{quoted(table)} (
        ID integer,
        FIRST_NAME string,
        LAST_NAME string,
        ROLE string,
        AGE integer
    )
    """
    cursor.execute(ddl)


def truncate_table(cursor, database: str, schema: str, table: str) -> None:
    cursor.execute(
        f"truncate table {quoted(database)}.{quoted(schema)}.{quoted(table)}"
    )


def insert_rows(cursor, database: str, schema: str, table: str, rows: Iterable[Tuple[int, str, str, str, int]]) -> int:
    insert_sql = (
        f"insert into {quoted(database)}.{quoted(schema)}.{quoted(table)} "
        "(ID, FIRST_NAME, LAST_NAME, ROLE, AGE) values (%s, %s, %s, %s, %s)"
    )
    cursor.executemany(insert_sql, list(rows))
    return cursor.rowcount or 0


def main() -> None:
    args = parse_args()

    connection_args: Dict[str, str] = {
        "account": require(os.getenv("SNOWFLAKE_ACCOUNT"), "SNOWFLAKE_ACCOUNT"),
        "user": require(os.getenv("SNOWFLAKE_USER"), "SNOWFLAKE_USER"),
        "password": require(os.getenv("SNOWFLAKE_PASSWORD"), "SNOWFLAKE_PASSWORD"),
        "warehouse": require(
            args.warehouse or os.getenv("SNOWFLAKE_WAREHOUSE"), "SNOWFLAKE_WAREHOUSE"
        ),
        "database": require(
            args.database or os.getenv("SNOWFLAKE_DATABASE"), "SNOWFLAKE_DATABASE"
        ),
        "schema": require(args.schema or os.getenv("SNOWFLAKE_SCHEMA"), "SNOWFLAKE_SCHEMA"),
    }

    role = args.role or os.getenv("SNOWFLAKE_ROLE")
    if role:
        connection_args["role"] = role

    rows = load_rows(args.csv_path)
    print(f"Loaded {len(rows)} rows from {args.csv_path}")

    conn = snowflake.connector.connect(**connection_args)
    conn.autocommit = True
    try:
        with conn.cursor() as cur:
            create_table(cur, connection_args["database"], connection_args["schema"], args.table)
            if args.truncate:
                truncate_table(cur, connection_args["database"], connection_args["schema"], args.table)
            inserted = insert_rows(cur, connection_args["database"], connection_args["schema"], args.table, rows)
            print(f"Inserted {inserted} rows into {connection_args['database']}.{connection_args['schema']}.{args.table}")
    finally:
        conn.close()


if __name__ == "__main__":
    main()

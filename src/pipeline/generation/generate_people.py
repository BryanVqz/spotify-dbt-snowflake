#!/usr/bin/env python3
"""
Generate a CSV file with synthetic people data.

Columns: ID, First Name, Last Name, Role, Age
Defaults to 100 rows, but you can override with --rows.
Outputs to historical_data/landing/people.csv by default.
"""

import argparse
import csv
import random
from pathlib import Path
from typing import Optional


FIRST_NAMES = [
    "Alex",
    "Jordan",
    "Taylor",
    "Riley",
    "Casey",
    "Morgan",
    "Sydney",
    "Quinn",
    "Avery",
    "Parker",
]

LAST_NAMES = [
    "Smith",
    "Johnson",
    "Davis",
    "Brown",
    "Miller",
    "Wilson",
    "Moore",
    "Taylor",
    "Anderson",
    "Thomas",
]

ROLES = [
    "Data Engineer",
    "Data Analyst",
    "ML Engineer",
    "Product Manager",
    "DevOps Engineer",
    "Software Engineer",
    "QA Engineer",
    "Scrum Master",
]

PROJECT_ROOT = Path(__file__).resolve().parents[3]
LANDING_DIR = PROJECT_ROOT / "historical_data" / "landing"
DEFAULT_OUTPUT = LANDING_DIR / "people.csv"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate synthetic people data as CSV."
    )
    parser.add_argument(
        "--rows",
        type=int,
        default=100,
        help="Number of rows to generate (default: 100).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Optional override for the output CSV path.",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=None,
        help="Optional random seed for reproducible output.",
    )
    return parser.parse_args()


def generate_row(row_id: int) -> dict:
    return {
        "ID": row_id,
        "First Name": random.choice(FIRST_NAMES),
        "Last Name": random.choice(LAST_NAMES),
        "Role": random.choice(ROLES),
        "Age": random.randint(21, 65),
    }


def write_people_csv(rows: int, output: Path, seed: Optional[int] = None) -> Path:
    """Generate rows of people data and write to CSV."""
    if seed is not None:
        random.seed(seed)

    output.parent.mkdir(parents=True, exist_ok=True)

    with output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle, fieldnames=["ID", "First Name", "Last Name", "Role", "Age"]
        )
        writer.writeheader()
        for idx in range(1, rows + 1):
            writer.writerow(generate_row(idx))

    return output


def main() -> None:
    args = parse_args()
    target_path = args.output if args.output else DEFAULT_OUTPUT
    written = write_people_csv(args.rows, target_path, seed=args.seed)
    print(f"Wrote {args.rows} rows to {written}")


if __name__ == "__main__":
    main()

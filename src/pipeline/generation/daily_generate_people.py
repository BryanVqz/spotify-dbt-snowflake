#!/usr/bin/env python3
"""
Generate a timestamped daily people CSV into historical_data/landing.

Default: 100 rows written to historical_data/landing/people_YYYYMMDD_HHMMSS.csv.
"""

import argparse
from datetime import datetime

from .generate_people import LANDING_DIR, write_people_csv


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate daily timestamped CSV.")
    parser.add_argument(
        "--rows",
        type=int,
        default=100,
        help="Number of rows to generate (default: 100).",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=None,
        help="Optional random seed for reproducible output.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_path = LANDING_DIR / f"people_{timestamp}.csv"
    written = write_people_csv(args.rows, output_path, seed=args.seed)
    print(f"Daily file written: {written}")


if __name__ == "__main__":
    main()

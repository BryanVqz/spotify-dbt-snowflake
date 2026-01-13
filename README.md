# Spotify Pipeline Skeleton

Restructured repo for dbt + Python ingestion. Landing/processed/failed folders hold flat files, Python scripts live under `src/python`, and dbt assets sit under `dbt/`.

## Layout
- `historical_data/landing|processed|failed/`: file zones (landing keeps raw drops; processed/failed ready for archival or triage).
- `src/python/pipeline/generation/`: data generators (`generate_people`, `daily_generate_people`).
- `src/python/pipeline/ingestion/`: loaders (`load_to_snowflake` defaults to `historical_data/landing/people.csv`).
- `src/python/pipeline/utils/`: helpers (`csv_summary` for quick profiling).
- `dbt/`: dbt project root (`dbt_project.yml`, `profiles.yml`, `models/`, `macros/`, etc.).
- `.venv/`, `requirements.txt`, `.gitignore`: Python env + dependency pins.

## Setup
```bash
cd /Users/bryan.quezadavasquez/Library/CloudStorage/OneDrive-Slalom/Documents/development/dbt/spotify-pipeline
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export PYTHONPATH=src/python  # consider adding to your shell rc
```

Snowflake env vars needed: `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_SCHEMA` (optional: `SNOWFLAKE_ROLE`).

## Generate files
```bash
# Single file (default: historical_data/landing/people.csv)
PYTHONPATH=src/python .venv/bin/python -m pipeline.generation.generate_people --rows 100 --seed 42

# Timestamped daily file in landing/
PYTHONPATH=src/python .venv/bin/python -m pipeline.generation.daily_generate_people --rows 100
```

## Load to Snowflake
```bash
PYTHONPATH=src/python .venv/bin/python -m pipeline.ingestion.load_to_snowflake \
  --csv-path historical_data/landing/people.csv \
  --table PEOPLE \
  --truncate

# After a successful load, move the source file to historical_data/processed/ (or failed/)
mv historical_data/landing/people.csv historical_data/processed/  # example manual archive
```

## dbt
```bash
cd dbt
../.venv/bin/dbt debug --profiles-dir .   # verify Snowflake connectivity
../.venv/bin/dbt run --profiles-dir .     # runs models (currently a stub)
```

## Next ideas
- Wire loaders to automatically archive landing files into processed/failed.
- Expand generators to produce Spotify-specific extracts.
- Flesh out dbt staging + marts, add tests, and schedule runs.

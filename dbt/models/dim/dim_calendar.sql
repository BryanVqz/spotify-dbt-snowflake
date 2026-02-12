WITH date_params AS (
  SELECT
    '2010-01-01'::DATE AS start_date,
    CURRENT_DATE()::DATE AS end_date
),

date_range AS (
  SELECT
    start_date,
    end_date,
    DATEDIFF(day, start_date, end_date) + 1 AS total_days
  FROM date_params
),

calendar AS (
  SELECT
    DATEADD(day, SEQ4(), dr.start_date)::DATE AS calendar_date
  FROM TABLE(GENERATOR(rowcount => 20000)) AS g,
       date_range dr
  WHERE SEQ4() < dr.total_days
)

SELECT
  TO_NUMBER(TO_CHAR(calendar_date, 'YYYYMMDD')) AS date_key,
  calendar_date,
  EXTRACT(YEAR FROM calendar_date) AS year,
  EXTRACT(MONTH FROM calendar_date) AS month,
  EXTRACT(DAY FROM calendar_date) AS day,
  EXTRACT(QUARTER FROM calendar_date) AS quarter,
  TO_CHAR(calendar_date, 'MMMM YYYY') AS month_year,
  TO_CHAR(calendar_date, 'MMMM') AS month_name,
  TO_CHAR(calendar_date, 'DY') AS day_name,
  CASE WHEN DAYOFWEEK(calendar_date) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend,
  WEEKOFYEAR(calendar_date) AS week_of_year,
  DAYOFYEAR(calendar_date) AS day_of_year,
  CURRENT_TIMESTAMP() AS meta_last_modified
FROM calendar
ORDER BY calendar_date
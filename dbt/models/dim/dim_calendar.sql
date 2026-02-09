{% set start_date = '2010-01-01' %}
{% set years_future = 2 %}

WITH date_params AS (
  SELECT
    '{{ start_date }}'::DATE AS start_date,
    DATEADD(year, {{ years_future }}, CURRENT_DATE())::DATE AS end_date
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
  FROM TABLE(GENERATOR(rowcount => 10000)),  -- Max possible, filtered below
       date_range dr
  WHERE SEQ4() < dr.total_days
)

SELECT
  -- Keys
  TO_NUMBER(TO_CHAR(calendar_date, 'YYYYMMDD')) AS date_key,
  calendar_date,
  
  -- Basic date parts
  EXTRACT(YEAR FROM calendar_date) AS year,
  EXTRACT(MONTH FROM calendar_date) AS month,
  EXTRACT(DAY FROM calendar_date) AS day,
  EXTRACT(QUARTER FROM calendar_date) AS quarter,
  
  -- Formatted strings
  TO_CHAR(calendar_date, 'MMMM YYYY') AS month_year,
  TO_CHAR(calendar_date, 'MMMM') AS month_name,
  TO_CHAR(calendar_date, 'DY') AS day_name,
  
  -- Useful flags
  CASE WHEN DAYOFWEEK(calendar_date) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend,
  
  -- Week/Year helpers
  WEEKOFYEAR(calendar_date) AS week_of_year,
  DAYOFYEAR(calendar_date) AS day_of_year,

  -- Metadata
  CURRENT_TIMESTAMP() AS meta_last_modified

FROM calendar
ORDER BY calendar_date
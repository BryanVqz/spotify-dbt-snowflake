WITH calendar AS (
  SELECT
    DATEADD(day, SEQ4(), '2015-01-01'::DATE)::DATE AS calendar_date
  FROM TABLE(GENERATOR(rowcount => 5475))  -- 15 years
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
  TO_CHAR(calendar_date, 'MMM YYYY') AS month_year,  -- "Feb 2024"
  TO_CHAR(calendar_date, 'MMMM') AS month_name,      -- "February"
  TO_CHAR(calendar_date, 'DY') AS day_name,          -- "Fri"
  
  -- Useful flags
  CASE WHEN DAYOFWEEK(calendar_date) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend,
  CASE WHEN calendar_date <= CURRENT_DATE() THEN TRUE ELSE FALSE END AS is_past,
  
  -- Week/Year helpers
  WEEKOFYEAR(calendar_date) AS week_of_year,
  DAYOFYEAR(calendar_date) AS day_of_year,

  -- Metadata
  CURRENT_TIMESTAMP() AS meta_loaded_at

FROM calendar
WHERE calendar_date <= DATEADD(year, 2, CURRENT_DATE())
ORDER BY calendar_date
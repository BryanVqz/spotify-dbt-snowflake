-- Simple Snowflake calendar: last 10 years through today.
with calendar as (
  select
    dateadd(
      day,
      seq4(),
      dateadd(day, -3650, current_date())
    )::date as calendar_date
  from table(generator(rowcount => 3651))
)
select
  to_number(to_char(calendar_date, 'YYYYMMDD')) as date_key,
  calendar_date,
  extract(year from calendar_date) as year,
  extract(month from calendar_date) as month,
  to_char(calendar_date, 'YYYY-MM') as year_month,
  extract(day from calendar_date) as day_of_month,
  extract(quarter from calendar_date) as quarter,
  trim(to_char(calendar_date, 'Month')) as month_name,
  trim(to_char(calendar_date, 'Day')) as day_name,
  extract(dow from calendar_date) as day_of_week
from calendar
where calendar_date <= current_date()
order by calendar_date

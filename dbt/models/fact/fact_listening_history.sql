with base as (
  select
    listening_timestamp,
    track_uri,
    platform,
    country,
    user_id,
    ms_played,
    reason_start,
    reason_end,
    shuffle_flag,
    skipped_flag,
    offline_flag,
    incognito_flag,
    meta_file_name,
    meta_last_modified
  from {{ ref('stg_listening') }}
),
track_dim as (
  select track_id, track_uri from {{ ref('dim_tracks') }}
),
device_dim as (
  select device_id, platform from {{ ref('dim_devices') }}
),
country_dim as (
  select country_id, country from {{ ref('dim_countries') }}
),
user_dim as (
  select user_id_key, user_id from {{ ref('dim_users') }}
),
calendar_dim as (
  select date_key, calendar_date from {{ ref('dim_calendar') }}
)
select
  cal.date_key,
  t.track_id,
  d.device_id,
  c.country_id,
  u.user_id_key,
  b.listening_timestamp,
  b.ms_played as total_ms_played,
  b.reason_start,
  b.reason_end,
  b.shuffle_flag,
  b.skipped_flag,
  b.offline_flag,
  b.incognito_flag,
  b.meta_file_name,
  b.meta_last_modified
from base b
left join track_dim t
  on b.track_uri = t.track_uri
left join device_dim d
  on b.platform = d.platform
left join country_dim c
  on b.country = c.country
left join user_dim u
  on b.user_id = u.user_id
left join calendar_dim cal
  on cal.calendar_date = date_trunc('day', b.listening_timestamp)::date

with track_data as (
  select distinct
    track_uri,
    track_name,
    artist_name,
    album_name
  from {{ ref('stg_listening') }}
  where track_uri is not null
)
select
  {{ dbt_utils.generate_surrogate_key(['track_uri']) }} as track_id,
  track_uri,
  track_name,
  artist_name,
  album_name
from track_data

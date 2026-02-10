with track_data as (
  select
    track_uri,
    max(track_name) as track_name,
    max(artist_name) as artist_name,
    max(album_name) as album_name
  from {{ ref('stg_listening') }}
  where track_uri is not null
  group by track_uri
)
select
  {{ dbt_utils.generate_surrogate_key(['track_uri']) }} as track_id,
  track_uri,
  track_name,
  artist_name,
  album_name
from track_data

select
  track_id,
  track_uri,
  track_name,
  artist_name,
  album_name
from {{ ref('stg_tracks') }}

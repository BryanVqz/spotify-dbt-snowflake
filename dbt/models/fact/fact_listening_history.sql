WITH streaming_history as (
    select * from {{ ref('stg_listening') }}
)

SELECT * FROM streaming_history
WHERE ARTIST_NAME IS NULL
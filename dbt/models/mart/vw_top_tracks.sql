WITH streaming_history AS (
    SELECT 
        *,
        MIN(listening_timestamp) OVER (
            PARTITION BY user_id, artist_name, album_name, track_name
        ) AS first_ever_played
    FROM {{ ref('fact_listening_history') }}
    WHERE user_id = 0001
)

SELECT 
    user_id,
    artist_name,
    album_name,
    track_name,
    COUNT(*) AS play_count_2025,
    DATE(MIN(first_ever_played)) AS first_ever_played,  -- First time EVER
    DATE(MIN(listening_timestamp)) AS first_played_date,
    DATE(MAX(listening_timestamp)) AS last_played_date,
    (SELECT DATE(MAX(listening_timestamp)) 
     FROM streaming_history
     WHERE user_id = 0001) AS latest_snapshot_date
FROM streaming_history
WHERE YEAR(listening_timestamp) = 2025
GROUP BY 
    user_id,
    artist_name,
    album_name,
    track_name
ORDER BY play_count_2025 DESC
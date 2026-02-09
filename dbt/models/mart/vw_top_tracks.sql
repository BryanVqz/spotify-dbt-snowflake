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
    COUNT(*) AS play_count,
    DATE(MIN(first_ever_played)) AS first_ever_played,
    
    -- Time metrics
    ROUND(SUM(ms_played) / 60000.0, 2) AS total_minutes,
    ROUND(SUM(ms_played) / 3600000.0, 2) AS total_hours,
    ROUND(AVG(ms_played) / 60000.0, 2) AS avg_minutes_per_play,
    ROUND(AVG(ms_played) / 1000.0, 2) AS avg_seconds_per_play,
    
    -- Dates
    DATE(MIN(listening_timestamp)) AS first_played_date_2025,
    DATE(MAX(listening_timestamp)) AS last_played_date_2025,
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
ORDER BY play_count DESC
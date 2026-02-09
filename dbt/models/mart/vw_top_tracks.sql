WITH streaming_history AS (
    SELECT * FROM {{ ref('fact_listening_history') }}
)

SELECT 
    user_id,
    artist_name,
    album_name,
    track_name,
    COUNT(track_name) AS play_count,
    DATE(MIN(listening_timestamp)) AS first_played_date,
    DATE(MAX(listening_timestamp)) AS last_played_date,
    (SELECT DATE(MAX(listening_timestamp)) 
     FROM streaming_history 
     WHERE USER_ID = 0001) AS latest_listening_date
FROM streaming_history
WHERE user_id = 0001  
    AND YEAR(listening_timestamp) = 2025
GROUP BY 
    user_id,
    artist_name,
    album_name,
    track_name
ORDER BY play_count DESC
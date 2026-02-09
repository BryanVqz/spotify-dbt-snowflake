WITH streaming_history as (
    select * from {{ ref('fact_listening_history') }}
)

SELECT
user_id
,artist_name
,album_name
,track_name

,count(track_name)
,date(min(listening_timestamp))
,date(max(listening_timestamp))

,(select date(max(listening_timestamp)) from streaming_history WHERE USER_ID = 0001)
FROM streaming_history
WHERE USER_ID = 0001
--AND DATE(listening_timestamp) BETWEEN '2024-01-01' AND '2024-12-31'
AND YEAR(listening_timestamp) = 2025
GROUP BY 
user_id
,artist_name
,album_name
,track_name
--,date(listening_timestamp)

ORDER BY 5 DESC
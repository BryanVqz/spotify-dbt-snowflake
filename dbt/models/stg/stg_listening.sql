WITH raw_spotify_data AS (
    SELECT
    USER_ID
    ,raw:ts::date                                      AS listening_date
    ,raw:conn_country::string                          AS country
    ,raw:master_metadata_album_album_name::string      AS album_name
    ,raw:master_metadata_album_artist_name::string     AS artist_name
    ,raw:master_metadata_track_name::string            AS track_name
    ,raw:ms_played::integer                            AS ms_played
    ,raw:platform::string                              AS platform
    ,raw:reason_start::string                          AS reason_start
    ,raw:reason_end::string                            AS reason_end
    ,raw:shuffle::boolean                              AS shuffle_flag
    ,raw:skipped::boolean                              AS skipped_flag
    ,raw:offline::boolean                              AS offline_flag
    ,raw:incognito_mode::boolean                       AS incognito_flag
    ,raw:spotify_track_uri::string                     AS track_uri
    ,raw:ts::timestamp                                 AS listening_timestamp
    ,file_name                                         AS meta_file_name
    ,s3_last_modified                                  AS meta_last_modified
    FROM {{ source('spotify','listening_raw') }}
    --FROM spotify_analytics.bronze.streaming_history_raw
)

SELECT *
--     REPLACE(user, 'Spotify ', '')                                                       AS user 
--     ,listening_timestamp
--     ,country
--     ,album_name
--     ,artist_name
--     ,track_name
--     ,ms_played
--     ,platform
--     ,CASE WHEN reason_start = '' THEN 'trackstart' ELSE reason_start END                 AS reason_start
--     ,CASE WHEN reason_end = '' THEN 'trackend' ELSE reason_end END                     AS reason_end
--     ,CASE WHEN shuffle IS NULL THEN 'false' ELSE shuffle END                             AS shuffle_flag
--     ,CASE WHEN skipped IS NULL THEN 'false' ELSE skipped END                             AS skipped_flag
--     ,CASE WHEN offline IS NULL THEN 'false' ELSE offline END                             AS offline_flag
--     ,CASE WHEN incognito_mode IS NULL THEN 'false' ELSE incognito_mode END               AS incognito_flag
FROM raw_spotify_data
WHERE track_uri IS NOT NULL

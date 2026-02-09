WITH country_data AS (
    SELECT DISTINCT
        country
        ,MAX(meta_last_modified) AS meta_last_modified
    FROM {{ ref('stg_listening') }}
    WHERE country IS NOT NULL
    GROUP BY country
)

,country_detailed AS (
    SELECT * FROM {{ ref('seed_countries') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['CD.country']) }}  AS country_id
    ,CDL.country
    ,CDL.name
    ,CD.meta_last_modified

FROM country_data CD
LEFT JOIN country_detailed CDL ON CD.country = CDL.country
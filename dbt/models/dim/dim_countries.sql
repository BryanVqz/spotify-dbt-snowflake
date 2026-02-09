WITH country_data AS (
  SELECT * FROM {{ ref('stg_countries') }}
)

,country_detailed AS (
    SELECT * FROM {{ ref('seed_countries') }}
)

SELECT
    CD.country_id
    ,CD.country
    ,CDL.name
FROM country_data CD
LEFT JOIN country_detailed CDL ON CD.country = CDL.country
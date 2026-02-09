WITH country_data AS (
    SELECT DISTINCT
        country
    FROM {{ ref('stg_listening') }}
    WHERE country IS NOT NULL
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['country']) }}  AS country_id
    ,country
FROM country_data
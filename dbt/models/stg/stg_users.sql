with source as (
    select *
    from {{ ref('stg_listening') }}
),

deduped as (
    select distinct
        "user" as user_id
    from source
    where "user" is not null
)

select *
from deduped

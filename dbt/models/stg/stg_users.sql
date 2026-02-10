with user_data as (
  select distinct
    user_id
  from {{ ref('stg_listening') }}
  where user_id is not null
)
select
  {{ dbt_utils.generate_surrogate_key(['user_id']) }} as user_id_key,
  user_id
from user_data

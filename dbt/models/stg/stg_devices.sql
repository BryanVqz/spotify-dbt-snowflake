with device_data as (
  select distinct
    platform
  from {{ ref('stg_listening') }}
  where platform is not null
)
select
  {{ dbt_utils.generate_surrogate_key(['platform']) }} as device_id,
  platform
from device_data

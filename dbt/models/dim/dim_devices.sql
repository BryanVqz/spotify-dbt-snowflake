select
  device_id,
  platform
from {{ ref('stg_devices') }}

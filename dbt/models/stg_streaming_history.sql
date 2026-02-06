select
  *
from {{ source('bronze', 'streaming_history_raw') }}

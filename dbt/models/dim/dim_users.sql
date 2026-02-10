select
  user_id_key,
  user_id
from {{ ref('stg_users') }}

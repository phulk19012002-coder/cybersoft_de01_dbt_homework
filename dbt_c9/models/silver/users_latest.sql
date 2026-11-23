{{ config(materialized='ephemeral') }}

with ranked as (
    select
        *,
        {{ latest_rank() }} as rn
    from {{ source('stylehub_bronze', 'users') }}
)

select
    id,
    first_name,
    last_name,
    email,
    age,
    gender,
    country,
    state,
    city,
    street_address,
    postal_code,
    latitude,
    longitude,
    traffic_source,
    created_at,
    updated_at
from ranked
where rn = 1
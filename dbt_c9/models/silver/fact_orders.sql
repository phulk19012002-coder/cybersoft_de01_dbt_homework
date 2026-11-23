{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='order_key'
) }}

with keyed as (
    select
        s.*,
        {{ dbt_utils.generate_surrogate_key(['id', 'created_at', 'updated_at']) }} as order_key
    from {{ source('stylehub_bronze', 'orders') }} as s
    {% if is_incremental() %}
    where s._airbyte_extracted_at >= (select max(ingested_at) from {{ this }})
    {% endif %}
),

ranked as (
    select
        *,
        {{ latest_rank('order_key') }} as rn
    from keyed
)

select
    order_key,
    id as order_id,
    user_id,
    status as order_status,
    date(created_at) as order_date,
    created_at,
    updated_at,
    total_amount,
    status = 'Returned' as is_returned,
    _airbyte_extracted_at as ingested_at,
    timestamp_diff(cast(_airbyte_extracted_at as datetime), updated_at, minute) as lag_min
from ranked
where rn = 1
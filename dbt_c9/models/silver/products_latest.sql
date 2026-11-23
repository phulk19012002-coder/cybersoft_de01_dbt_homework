with ranked as (
    select
        *,
        {{ latest_rank('id') }} as rn
    from {{ source('stylehub_bronze', 'products') }}
)

select
    id,
    name,
    category,
    brand,
    department,
    sku,
    cost,
    retail_price,
    updated_at
from ranked
where rn = 1
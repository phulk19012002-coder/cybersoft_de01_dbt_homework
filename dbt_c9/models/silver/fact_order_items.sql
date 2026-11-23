{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='order_item_key'
) }}

with keyed as (
    select
        s.*,
        {{ dbt_utils.generate_surrogate_key(['id', 'created_at', 'updated_at']) }} as order_item_key
    from {{ source('stylehub_bronze', 'order_items') }} as s
    {% if is_incremental() %}
    where s._airbyte_extracted_at >= (select max(ingested_at) from {{ this }})
    {% endif %}
),

ranked as (
    select
        *,
        {{ latest_rank('order_item_key') }} as rn
    from keyed
),

items as (
    select
        order_item_key,
        id as order_item_id,
        order_id,
        product_id,
        sale_price,
        quantity,
        amount,
        created_at,
        updated_at,
        _airbyte_extracted_at as ingested_at
    from ranked
    where rn = 1
),

latest_orders as (
    select
        *,
        row_number() over (
            partition by order_id
            order by updated_at desc, ingested_at desc
        ) as rn
    from {{ ref('fact_orders') }}
)

select
    i.order_item_key,
    i.order_item_id,
    i.order_id,
    i.product_id,
    o.user_id,
    o.order_status,
    o.order_date,
    i.sale_price,
    i.quantity,
    i.amount,
    p.cost * i.quantity as total_cost,
    i.created_at,
    i.updated_at,
    i.ingested_at
from items as i
join latest_orders as o
    on i.order_id = o.order_id
    and o.rn = 1
left join {{ ref('dim_products') }} as p
    on i.product_id = p.product_id
select
    order_date,
    count(distinct order_id) as total_orders,
    sum(amount) as revenue,
    sum(total_cost) as total_cost
from {{ ref('fact_order_items') }}
where order_status not in ('Cancelled', 'Returned')
group by order_date
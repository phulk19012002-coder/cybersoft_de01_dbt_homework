
with gold_monthly as (
    select
        order_month,
        round(cast(sum(revenue) as numeric), 2) as gold_revenue
    from {{ ref('gold_revenue_by_month_category') }}
    group by order_month
),

silver_monthly as (
    select
        date_trunc(date(o.order_date), month) as order_month,
        round(cast(sum(i.amount) as numeric), 2) as silver_revenue
    from {{ ref('fact_order_items') }} as i
    join {{ ref('fact_orders') }} as o
        on i.order_id = o.order_id
    where o.order_status not in ('Cancelled', 'Returned')
    group by order_month
)

select
    coalesce(g.order_month, s.order_month) as order_month,
    coalesce(g.gold_revenue, 0) as gold_revenue,
    coalesce(s.silver_revenue, 0) as silver_revenue,
    coalesce(g.gold_revenue, 0) - coalesce(s.silver_revenue, 0) as diff
from gold_monthly as g
full outer join silver_monthly as s
    on g.order_month = s.order_month
where coalesce(g.gold_revenue, 0) != coalesce(s.silver_revenue, 0)
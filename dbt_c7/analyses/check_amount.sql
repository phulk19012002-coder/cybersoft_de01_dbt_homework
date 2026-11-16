select
    order_item_id,
    order_id,
    product_id,
    sale_price,
    quantity,
    amount,
    sale_price * quantity as expected_amount,
    amount - (sale_price * quantity) as difference
from {{ ref('fact_order_items') }}
where amount != sale_price * quantity
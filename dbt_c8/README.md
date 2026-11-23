# StyleHub dbt — Chapter 8 Homework (`dbt_c8`)

## 0. Đầu vào cần có

Install `dbt_utils`, verify connection, materialize Silver models, and run Silver data quality tests (`dim_products`, `dim_users`, `fact_orders`, `fact_order_items`, `fact_shipments`):

```bash
dbt deps
dbt debug
dbt run --select dim_products dim_users fact_orders fact_order_items fact_shipments
dbt test --select dim_products dim_users fact_orders fact_order_items fact_shipments
```

## 1. Dựng bảng Gold

Materialize `models/gold/gold_revenue_by_month_category.sql` (`order_month`, `category`, `total_orders`, `revenue`, `profit` joining `fact_order_items`, `fact_orders`, and `dim_products`, excluding `Cancelled` and `Returned` orders):

```bash
dbt run --select gold_revenue_by_month_category
```

## 2. Viết test cho bảng Gold

### Schema & `dbt_utils` Tests (`models/gold/_gold.yml`)
- **Grain uniqueness:** `dbt_utils.unique_combination_of_columns` on `[order_month, category]`
- **Validity:** `dbt_utils.accepted_range` (`revenue >= 0`)
- **Completeness:**
  - `order_month`: `not_null` (`severity: error`)
  - `category`: `not_null` (`severity: warn` — retains uncategorized items in total revenue while flagging missing product metadata)

### Singular Test (`tests/assert_gold_revenue_matches_silver.sql`)
Cross-checks total `revenue` in `gold_revenue_by_month_category` against `sum(amount)` from `fact_order_items` joined with `fact_orders` (excluding `Cancelled` and `Returned`).

```bash
dbt test --select gold_revenue_by_month_category assert_gold_revenue_matches_silver
```

## 3. Chạy và đọc kết quả

Run model materialization and all attached tests in DAG order:

```bash
dbt build --select gold_revenue_by_month_category
```

- **Execution Result:** `Processed: 1 model | 5 tests — Summary: 6 total | 6 success` (All 4 schema/`dbt_utils` tests and `assert_gold_revenue_matches_silver` passed with `0` failing rows).

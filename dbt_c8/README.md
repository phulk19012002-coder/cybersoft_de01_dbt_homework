# StyleHub dbt — Session 8 Homework (`dbt_c8`)

## 0. Prerequisites (Packages & Silver Layer Tests)

Install `dbt_utils`, materialize Silver models, and execute Silver data quality tests (`dim_products`, `dim_users`, `fact_orders`, `fact_order_items`, `fact_shipments`):

```bash
dbt deps
dbt debug
dbt run --select dim_products dim_users fact_orders fact_order_items fact_shipments
dbt test --select dim_products dim_users fact_orders fact_order_items fact_shipments
```

## 1. Gold Layer (`gold_revenue_by_month_category`)

Materialize `models/gold/gold_revenue_by_month_category.sql` (`order_month`, `category`, `total_orders`, `revenue`, `profit` joining `fact_order_items`, `fact_orders`, and `dim_products`, excluding `Cancelled` and `Returned` orders):

```bash
dbt run --select gold_revenue_by_month_category
```

## 2. Gold Data Quality Tests

### Schema & `dbt_utils` Tests (`models/gold/_gold.yml`)
- **Grain uniqueness:** `dbt_utils.unique_combination_of_columns` on `[order_month, category]`
- **Validity:** `dbt_utils.accepted_range` (`revenue >= 0`)
- **Completeness:**
  - `order_month`: `not_null` (`severity: error`)
  - `category`: `not_null` (`severity: warn` — retains uncategorized items in total revenue while flagging missing product metadata)

### Singular Reconciliation Test (`tests/assert_gold_revenue_matches_silver.sql`)
Cross-checks total `revenue` in `gold_revenue_by_month_category` against `sum(amount)` from `fact_order_items` joined with `fact_orders` (excluding `Cancelled` and `Returned`).

```bash
dbt test --select gold_revenue_by_month_category assert_gold_revenue_matches_silver
```

## 3. End-to-End Build & Verification

Run model materialization and all attached tests in DAG order:

```bash
dbt build --select gold_revenue_by_month_category
```

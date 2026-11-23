# StyleHub dbt Homework (`DE01`)

End-to-end Medallion transformation and data quality pipeline (`Bronze` -> `Silver` -> `Gold`) on **Google BigQuery** using **dbt**.

## Repository Structure

| Directory | Chapter | Scope |
| :--- | :--- | :--- |
| [`./dbt_c7`](./dbt_c7) | **Chapter 7 — dbt Fundamentals** | Sources, Silver dimensions/facts, `latest_rank` macro, `daily_revenue` Gold table, `check_amount` analysis, DAG lineage. |
| [`./dbt_c8`](./dbt_c8) | **Chapter 8 — Data Quality & Testing** | Generic, `dbt_utils`, and singular tests across Silver & Gold (`gold_revenue_by_month_category`), test severity (`warn`/`error`), reconciliation assertions. |
| [`./dbt_c9`](./dbt_c9) | **Chapter 9 — Incremental Models & Snapshots** | Incremental `merge` models (`fact_orders`, `fact_shipments`, `fact_order_items`), SCD Type 1/2 snapshots (`products_snapshot`, `users_snapshot`, `dim_users_type2`), BigQuery `MB` processed benchmarking (`log_bytes_processed`). |

## Environment Setup

```bash
# 1. Install Python dependencies
uv sync

# 2. Configure BigQuery profile in ~/.dbt/profiles.yml
# 3. Navigate to target project and verify connection
cd dbt_c7  # or cd dbt_c8 / cd dbt_c9
dbt deps
dbt debug
```

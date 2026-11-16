# StyleHub dbt Homework (`DE01`)

End-to-end Medallion transformation and data quality pipeline (`Bronze` -> `Silver` -> `Gold`) on **Google BigQuery** using **dbt**.

## Repository Structure

| Directory | Session | Scope |
| :--- | :--- | :--- |
| [`./dbt_c7`](./dbt_c7) | **Session 7 — dbt Fundamentals** | Sources, Silver dimensions/facts, `latest_rank` macro, `daily_revenue` Gold table, `check_amount` analysis, DAG lineage. |
| [`./dbt_c8`](./dbt_c8) | **Session 8 — Data Quality & Testing** | Generic, `dbt_utils`, and singular tests across Silver & Gold (`gold_revenue_by_month_category`), test severity (`warn`/`error`), reconciliation assertions. |

## Environment Setup

```bash
# 1. Install Python dependencies
uv sync

# 2. Configure BigQuery profile in ~/.dbt/profiles.yml
# 3. Navigate to target project and verify connection
cd dbt_c7  # or cd dbt_c8
dbt deps
dbt debug
```

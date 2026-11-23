# StyleHub dbt — Chapter 9 Homework (`dbt_c9`)

## 0. Đầu vào cần có

Install `dbt_utils`, verify connection, run `products_snapshot`, and materialize SCD Type 1/2 product dimensions along with incremental `fact_orders` and `fact_shipments`:

```bash
dbt deps
dbt debug
dbt snapshot --select products_snapshot
dbt run --select dim_products dim_users dim_products_type1 dim_products_type2
dbt run --select fact_orders fact_shipments --full-refresh
```

## 1. `fact_order_items` chỉ thêm

Convert `models/silver/fact_order_items.sql` to an append-versioned incremental model (`incremental_strategy='merge'`, `unique_key='order_item_key'`):
- **Surrogate key:** `dbt_utils.generate_surrogate_key(['id', 'created_at', 'updated_at'])`
- **Batch deduplication:** `latest_rank('order_item_key')`
- **Incremental watermark:** `where s._airbyte_extracted_at >= (select max(ingested_at) from {{ this }})`
- **Schema tests (`models/silver/_silver.yml`):** Replaced `unique_combination_of_columns` on `[order_id, product_id]` with `unique` and `not_null` on `order_item_key`; retained `expression_is_true` (`amount = sale_price * quantity`) and foreign key `relationships`.

## 2. Snapshot cho `users` và bảng lịch sử

- **`models/silver/users_latest.sql` (`ephemeral`):** Deduplicates Bronze `users` to the latest record per `id`.
- **`snapshots/users_snapshot.yml`:** Tracks user history from `ref('users_latest')` using `strategy: check` on mutable profile/address columns (`first_name`, `last_name`, `email`, `age`, `gender`, `country`, `state`, `city`, `street_address`, `postal_code`) with custom meta columns (`valid_from`, `valid_to`, `scd_id`, `snapshot_updated_at`).
- **`models/silver/dim_users_type2.sql`:** Builds SCD Type 2 user dimension (`user_key`, `user_id`, user attributes, `valid_from`, `valid_to`, `is_current`), tested with `unique` and `not_null` on `user_key`.

## 3. Chạy và đếm dòng

### 3.1. `fact_order_items` (3 consecutive runs without source changes)

```bash
dbt run --select fact_order_items --full-refresh
dbt run --select fact_order_items
dbt run --select fact_order_items
```

```sql
select count(*) as row_count
from `data-engineer-project-510104.stylehub_dbt_silver.fact_order_items`;
```

- **Row Count Result:** **`988,127` rows** (identical across all 3 runs: `--full-refresh`, Incremental Run 1, and Incremental Run 2).

### 3.2. `users_snapshot` & `dim_users_type2` (2 consecutive snapshot runs + test verification)

```bash
dbt snapshot --select users_snapshot
dbt snapshot --select users_snapshot
dbt run --select dim_users_type2
dbt test --select fact_order_items dim_users_type2
```

```sql
select count(*) as row_count
from `data-engineer-project-510104.stylehub_dbt.users_snapshot`;
```

- **`users_snapshot` Row Count Result:** **`157,727` rows** (identical across both snapshot runs; `55.61 MB` on initial creation, `34.78 MB` on second run).
- **Test Execution Result:** `Processed: 1 hook | 12 tests — Summary: 13 total | 13 success`.

## 4. Đọc MB và viết nhận xét

### Bảng thống kê dung lượng xử lý (`fact_order_items` — `log_bytes_processed`)

| Lần chạy | Lệnh thực thi | Số dòng (`row_count`) | Dung lượng xử lý (`MB`) |
| :--- | :--- | :---: | :---: |
| **Lần 1 (Full-refresh)** | `dbt run --select fact_order_items --full-refresh` | `988,127` | **`170.95 MB`** |
| **Lần 2 (Incremental 1)** | `dbt run --select fact_order_items` | `988,127` | **`258.12 MB`** |
| **Lần 3 (Incremental 2)** | `dbt run --select fact_order_items` | `988,127` | **`258.12 MB`** |

### Nhận xét (6 dòng)
1. **So sánh số byte đọc:** Hai lần chạy `incremental` (`258.12 MB`) không đọc ít byte hơn mà tốn nhiều hơn **`87.17 MB` (+51%)** so với lần chạy `--full-refresh` (`170.95 MB`).
2. **Bảng nguồn chưa Partition theo cột lọc:** Bảng nguồn `stylehub_ab_bronze.order_items` chưa được partition theo cột `_airbyte_extracted_at`, nên dù có bộ lọc `WHERE _airbyte_extracted_at >= ...`, BigQuery vẫn phải quét toàn bộ (full scan) bảng nguồn giống như lúc full-refresh.
3. **Watermark là truy vấn con động:** Điều kiện `(SELECT MAX(ingested_at) FROM {{ this }})` là một subquery động buộc BigQuery phải đọc thêm cột `ingested_at` của bảng đích và không thể cắt tỉa partition tĩnh từ trước.
4. **Chi phí JOIN các bảng liên quan:** Ở mỗi lần chạy, model `fact_order_items` vẫn phải quét toàn bộ hai bảng `fact_orders` và `dim_products` để thực hiện phép `JOIN`.
5. **Chi phí lệnh `MERGE` quét bảng đích (`+87.17 MB`):** Ở lần `--full-refresh`, BigQuery chỉ chạy `CREATE OR REPLACE TABLE` ghi đè một chiều (`170.95 MB`); còn ở hai lần `incremental`, chiến lược `merge` buộc BigQuery phải quét thêm bảng đích `fact_order_items` để so khớp khóa `order_item_key` (`258.12 - 170.95 = 87.17 MB`).
6. **Kết luận:** Với bảng quy mô nhỏ và nguồn chưa partition theo cột watermark, incremental `merge` chưa giúp giảm số byte quét mà phục vụ mục tiêu cốt lõi về mặt nghiệp vụ: **lưu giữ lịch sử các phiên bản chỉnh sửa của món hàng mà không ghi đè làm mất bản cũ**.

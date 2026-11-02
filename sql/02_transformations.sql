-- ==============================================================================
-- 02_transformations.sql: Pipeline ELT de Carga y Transformación Dimensional
-- ==============================================================================

-- 1. Poblar dim_date (Generador de series de tiempo para 2023 a 2025)
INSERT INTO dim_date
SELECT
    CAST(strftime(d, '%Y%m%d') AS INTEGER) AS date_key,
    CAST(d AS DATE) AS full_date,
    CAST(EXTRACT('year' FROM d) AS INTEGER) AS year,
    CAST(EXTRACT('quarter' FROM d) AS INTEGER) AS quarter,
    CAST(EXTRACT('month' FROM d) AS INTEGER) AS month,
    strftime(d, '%B') AS month_name,
    CAST(EXTRACT('day' FROM d) AS INTEGER) AS day,
    CAST(EXTRACT('isodow' FROM d) AS INTEGER) AS day_of_week,
    strftime(d, '%A') AS day_name,
    CASE WHEN EXTRACT('isodow' FROM d) IN (6, 7) THEN TRUE ELSE FALSE END AS is_weekend
FROM generate_series(DATE '2023-01-01', DATE '2025-12-31', INTERVAL 1 DAY) AS t(d);

-- 2. Poblar dim_customers (Generación de Claves Subrogadas y Normalización)
INSERT INTO dim_customers
SELECT
    ROW_NUMBER() OVER (ORDER BY customer_id) AS customer_key,
    TRIM(customer_id) AS customer_id,
    TRIM(customer_name) AS customer_name,
    TRIM(country) AS country,
    TRIM(city) AS city,
    TRIM(segment) AS segment,
    CAST(signup_date AS DATE) AS signup_date
FROM read_csv_auto('data/raw/raw_customers.csv');

-- 3. Poblar dim_products (Catálogo y costos estándar)
INSERT INTO dim_products
SELECT
    ROW_NUMBER() OVER (ORDER BY product_id) AS product_key,
    TRIM(product_id) AS product_id,
    TRIM(product_name) AS product_name,
    TRIM(category) AS category,
    TRIM(subcategory) AS subcategory,
    CAST(unit_cost AS DECIMAL(10, 2)) AS unit_cost,
    CAST(standard_price AS DECIMAL(10, 2)) AS standard_price
FROM read_csv_auto('data/raw/raw_products.csv');

-- 4. Poblar fact_orders (Resolución de FKs, Enriquecimiento de Métricas Financieras)
INSERT INTO fact_orders
WITH raw_orders_stg AS (
    SELECT
        order_line_id,
        order_id,
        CAST(order_date AS DATE) AS order_date,
        CAST(order_time AS TIME) AS order_time,
        TRIM(customer_id) AS customer_id,
        TRIM(product_id) AS product_id,
        payment_method,
        quantity,
        CAST(unit_price AS DECIMAL(10, 2)) AS unit_price,
        CAST(discount_amount AS DECIMAL(12, 2)) AS discount_amount
    FROM read_csv_auto('data/raw/raw_orders.csv')
)
SELECT
    ROW_NUMBER() OVER (ORDER BY ro.order_date, ro.order_id, ro.order_line_id) AS order_item_key,
    ro.order_id,
    ro.order_line_id,
    dd.date_key AS order_date_key,
    dc.customer_key,
    dp.product_key,
    ro.order_time,
    ro.payment_method,
    ro.quantity,
    ro.unit_price,
    ROUND(ro.quantity * ro.unit_price, 2) AS gross_amount,
    ro.discount_amount,
    ROUND((ro.quantity * ro.unit_price) - ro.discount_amount, 2) AS net_amount,
    ROUND(ro.quantity * dp.unit_cost, 2) AS cost_amount,
    ROUND(((ro.quantity * ro.unit_price) - ro.discount_amount) - (ro.quantity * dp.unit_cost), 2) AS margin_amount
FROM raw_orders_stg ro
INNER JOIN dim_customers dc ON ro.customer_id = dc.customer_id
INNER JOIN dim_products dp ON ro.product_id = dp.product_id
INNER JOIN dim_date dd ON ro.order_date = dd.full_date;

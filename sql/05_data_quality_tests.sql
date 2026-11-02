-- ==============================================================================
-- 05_data_quality_tests.sql: Pruebas Automatizadas de Calidad e Integridad (Data Quality)
-- ==============================================================================
-- Cada prueba devuelve el número de registros que fallan la condición.
-- Un Data Warehouse saludable debe devolver 0 en todas las comprobaciones.

-- Test 1: Unicidad de Claves Primarias en Dimensiones
SELECT 
    'test_pk_uniqueness_dim_customers' AS test_name,
    COUNT(*) - COUNT(DISTINCT customer_key) AS failed_records
FROM dim_customers
UNION ALL
SELECT 
    'test_pk_uniqueness_dim_products',
    COUNT(*) - COUNT(DISTINCT product_key)
FROM dim_products
UNION ALL
SELECT 
    'test_pk_uniqueness_dim_date',
    COUNT(*) - COUNT(DISTINCT date_key)
FROM dim_date
UNION ALL
SELECT 
    'test_pk_uniqueness_fact_orders',
    COUNT(*) - COUNT(DISTINCT order_item_key)
FROM fact_orders

UNION ALL

-- Test 2: Integridad Referencial (Claves Foráneas Huérfanas)
SELECT
    'test_fk_orphan_customers' AS test_name,
    COUNT(*) AS failed_records
FROM fact_orders f
LEFT JOIN dim_customers c ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL

UNION ALL

SELECT
    'test_fk_orphan_products' AS test_name,
    COUNT(*) AS failed_records
FROM fact_orders f
LEFT JOIN dim_products p ON f.product_key = p.product_key
WHERE p.product_key IS NULL

UNION ALL

SELECT
    'test_fk_orphan_date' AS test_name,
    COUNT(*) AS failed_records
FROM fact_orders f
LEFT JOIN dim_date d ON f.order_date_key = d.date_key
WHERE d.date_key IS NULL

UNION ALL

-- Test 3: Reglas de Negocio Financieras (Consistencia de montos)
SELECT
    'test_business_logic_negative_quantities' AS test_name,
    COUNT(*) AS failed_records
FROM fact_orders
WHERE quantity <= 0

UNION ALL

SELECT
    'test_business_logic_net_amount_consistency' AS test_name,
    COUNT(*) AS failed_records
FROM fact_orders
WHERE net_amount != ROUND(gross_amount - discount_amount, 2);

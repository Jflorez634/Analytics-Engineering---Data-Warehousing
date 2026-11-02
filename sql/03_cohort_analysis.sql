-- ==============================================================================
-- 03_cohort_analysis.sql: Análisis de Retención por Cohortes de Clientes
-- ==============================================================================
-- Pregunta de Negocio: 
-- ¿Qué porcentaje de los clientes adquiridos en cada mes sigue comprando en los meses posteriores (Mes 0, Mes 1, Mes 2, ...)?
-- Técnicas: Common Table Expressions (CTEs), Funciones de Ventana y DATE_TRUNC

WITH customer_orders AS (
    -- Paso 1: Obtener la fecha de cada orden por cliente a partir de la tabla de hechos y fechas
    SELECT DISTINCT
        f.customer_key,
        d.full_date AS order_date,
        DATE_TRUNC('month', d.full_date) AS order_month
    FROM fact_orders f
    INNER JOIN dim_date d ON f.order_date_key = d.date_key
),

customer_first_purchase AS (
    -- Paso 2: Determinar la cohorte de cada cliente (mes de su primera compra)
    SELECT
        customer_key,
        MIN(order_month) AS cohort_month
    FROM customer_orders
    GROUP BY customer_key
),

cohort_activity AS (
    -- Paso 3: Calcular el índice del período (meses transcurridos desde la primera compra)
    SELECT
        co.customer_key,
        cfp.cohort_month,
        co.order_month,
        -- Cálculo de la diferencia en meses entre la orden y el mes de inicio de la cohorte
        (CAST(EXTRACT('year' FROM co.order_month) AS INTEGER) - CAST(EXTRACT('year' FROM cfp.cohort_month) AS INTEGER)) * 12 +
        (CAST(EXTRACT('month' FROM co.order_month) AS INTEGER) - CAST(EXTRACT('month' FROM cfp.cohort_month) AS INTEGER)) AS period_number
    FROM customer_orders co
    INNER JOIN customer_first_purchase cfp ON co.customer_key = cfp.customer_key
),

cohort_sizes AS (
    -- Paso 4: Tamaño total inicial de cada cohorte (período 0)
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_key) AS total_cohort_customers
    FROM cohort_activity
    WHERE period_number = 0
    GROUP BY cohort_month
),

cohort_retention AS (
    -- Paso 5: Clientes activos en cada período posterior y cálculo de tasa de retención (%)
    SELECT
        ca.cohort_month,
        cs.total_cohort_customers,
        ca.period_number,
        COUNT(DISTINCT ca.customer_key) AS active_customers,
        ROUND(COUNT(DISTINCT ca.customer_key) * 100.0 / cs.total_cohort_customers, 2) AS retention_rate_pct
    FROM cohort_activity ca
    INNER JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
    GROUP BY ca.cohort_month, cs.total_cohort_customers, ca.period_number
)

-- Resultado final tabulado
SELECT
    strftime(cohort_month, '%Y-%m') AS cohort,
    total_cohort_customers AS cohort_size,
    period_number AS month_offset,
    active_customers,
    retention_rate_pct
FROM cohort_retention
WHERE cohort_month >= '2023-01-01' AND cohort_month <= '2024-06-01'
ORDER BY cohort, month_offset;

-- ==============================================================================
-- 04_rfm_and_clv.sql: Segmentación RFM y Métricas de Customer Lifetime Value (CLV)
-- ==============================================================================
-- Técnicas: Window Functions (NTILE, SUM OVER), CASE WHEN, Agrupaciones Dimensionales

WITH customer_summary AS (
    -- Paso 1: Métricas base por cliente
    SELECT
        c.customer_key,
        c.customer_id,
        c.customer_name,
        c.country,
        c.segment AS market_segment,
        MIN(d.full_date) AS first_order_date,
        MAX(d.full_date) AS last_order_date,
        -- Recencia: Días transcurridos desde su última orden hasta la fecha de corte (2024-12-31)
        DATE_DIFF('day', MAX(d.full_date), DATE '2024-12-31') AS recency_days,
        -- Frecuencia: Número de órdenes distintas
        COUNT(DISTINCT f.order_id) AS frequency_orders,
        -- Valor Monetario: Ingreso neto total generado
        ROUND(SUM(f.net_amount), 2) AS monetary_value,
        -- Margen de beneficio total generado
        ROUND(SUM(f.margin_amount), 2) AS total_margin
    FROM fact_orders f
    INNER JOIN dim_customers c ON f.customer_key = c.customer_key
    INNER JOIN dim_date d ON f.order_date_key = d.date_key
    GROUP BY c.customer_key, c.customer_id, c.customer_name, c.country, c.segment
),

rfm_scoring AS (
    -- Paso 2: Asignación de cuartiles con NTILE(4)
    -- Para Recencia: Menos días de inactividad = Mayor puntaje (4)
    -- Para Frecuencia y Monetario: Mayor valor = Mayor puntaje (4)
    SELECT
        *,
        NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency_orders ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary_value ASC) AS m_score
    FROM customer_summary
),

rfm_segmented AS (
    -- Paso 3: Segmentación estratégica de clientes
    SELECT
        *,
        (r_score * 100 + f_score * 10 + m_score) AS rfm_combined,
        CASE
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions (Alto Valor)'
            WHEN f_score >= 3 THEN 'Clientes Leales / Frecuentes'
            WHEN r_score >= 3 AND f_score = 1 THEN 'Nuevos Prometedores'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'En Riesgo de Fuga'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Hibernando / Inactivos'
            ELSE 'Ocasionales / Potenciales'
        END AS customer_rfm_segment
    FROM rfm_scoring
)

-- Resumen de segmentación para reporte gerencial
SELECT
    customer_rfm_segment,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers,
    ROUND(AVG(recency_days), 1) AS avg_recency_days,
    ROUND(AVG(frequency_orders), 1) AS avg_orders,
    ROUND(AVG(monetary_value), 2) AS avg_monetary_value,
    ROUND(SUM(monetary_value), 2) AS total_revenue_generated,
    ROUND(SUM(total_margin), 2) AS total_profit_generated
FROM rfm_segmented
GROUP BY customer_rfm_segment
ORDER BY total_revenue_generated DESC;

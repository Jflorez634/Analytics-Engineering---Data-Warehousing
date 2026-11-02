-- ==============================================================================
-- 01_ddl_schemas.sql: Definición del Esquema Estrella (Kimball Star Schema)
-- Almacén de Datos Analítico para E-commerce en DuckDB
-- ==============================================================================

-- 1. Dimensión Calendario / Fecha (dim_date)
-- Permite agregaciones por año, trimestre, mes, día y análisis de estacionalidad
CREATE OR REPLACE TABLE dim_date (
    date_key        INTEGER PRIMARY KEY,       -- Formato YYYYMMDD (ej. 20230514)
    full_date       DATE NOT NULL,
    year            INTEGER NOT NULL,
    quarter         INTEGER NOT NULL,
    month           INTEGER NOT NULL,
    month_name      VARCHAR NOT NULL,
    day             INTEGER NOT NULL,
    day_of_week     INTEGER NOT NULL,          -- 1 = Lunes, 7 = Domingo
    day_name        VARCHAR NOT NULL,
    is_weekend      BOOLEAN NOT NULL
);

-- 2. Dimensión Clientes (dim_customers)
-- Clave subrogada (customer_key) + Clave natural (customer_id)
CREATE OR REPLACE TABLE dim_customers (
    customer_key    BIGINT PRIMARY KEY,        -- Clave subrogada generada para el DW
    customer_id     VARCHAR NOT NULL UNIQUE,   -- Clave natural del sistema operacional
    customer_name   VARCHAR NOT NULL,
    country         VARCHAR NOT NULL,
    city            VARCHAR NOT NULL,
    segment         VARCHAR NOT NULL,          -- Consumer, Corporate, Home Office
    signup_date     DATE NOT NULL
);

-- 3. Dimensión Productos (dim_products)
CREATE OR REPLACE TABLE dim_products (
    product_key     BIGINT PRIMARY KEY,        -- Clave subrogada
    product_id      VARCHAR NOT NULL UNIQUE,   -- Clave natural
    product_name    VARCHAR NOT NULL,
    category        VARCHAR NOT NULL,
    subcategory     VARCHAR NOT NULL,
    unit_cost       DECIMAL(10, 2) NOT NULL,
    standard_price  DECIMAL(10, 2) NOT NULL
);

-- 4. Tabla de Hechos: Órdenes y Líneas de Venta (fact_orders)
-- Grano: 1 fila = 1 artículo dentro de una orden de compra transaccional
CREATE OR REPLACE TABLE fact_orders (
    order_item_key   BIGINT PRIMARY KEY,       -- Clave subrogada del ítem de la orden
    order_id         VARCHAR NOT NULL,         -- Dimensión degenerada (ID transaccional)
    order_line_id    VARCHAR NOT NULL,
    order_date_key   INTEGER NOT NULL REFERENCES dim_date(date_key),
    customer_key     BIGINT NOT NULL REFERENCES dim_customers(customer_key),
    product_key      BIGINT NOT NULL REFERENCES dim_products(product_key),
    order_time       TIME,
    payment_method   VARCHAR NOT NULL,
    quantity         INTEGER NOT NULL,
    unit_price       DECIMAL(10, 2) NOT NULL,
    gross_amount     DECIMAL(12, 2) NOT NULL,  -- quantity * unit_price
    discount_amount  DECIMAL(12, 2) NOT NULL,
    net_amount       DECIMAL(12, 2) NOT NULL,  -- gross_amount - discount_amount
    cost_amount      DECIMAL(12, 2) NOT NULL,  -- quantity * unit_cost
    margin_amount    DECIMAL(12, 2) NOT NULL   -- net_amount - cost_amount
);

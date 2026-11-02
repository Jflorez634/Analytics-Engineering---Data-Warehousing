# 🏛️ E-Commerce Dimensional Data Warehouse & Advanced Analytics (Kimball Star Schema + DuckDB)

[![Area](https://img.shields.io/badge/Área-Analytics%20Engineering-green.svg)]()
[![Methodology](https://img.shields.io/badge/Data%20Modeling-Kimball%20Star%20Schema-blueviolet.svg)]()
[![Engine](https://img.shields.io/badge/Engine-DuckDB%20OLAP-yellow.svg?logo=duckdb&logoColor=black)](https://duckdb.org/)
[![SQL](https://img.shields.io/badge/SQL-Window%20Functions%20%26%20CTEs-lightgrey.svg?logo=postgresql&logoColor=white)]()
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB.svg?logo=python&logoColor=white)](https://www.python.org/)

> **Resumen Ejecutivo:** Diseño e implementación de un Data Warehouse analítico de extremo a extremo para E-commerce bajo el estándar dimensional de **Ralph Kimball (Esquema Estrella)**. Transforma registros transaccionales operacionales (OLTP) en un modelo desnormalizado optimizado para Business Intelligence en **DuckDB**, incorporando un pipeline **ELT en SQL puro**, pruebas automatizadas de calidad de datos (*Data Quality Tests*), **análisis de cohortes de retención mensual** mediante funciones de ventana y **segmentación estratégica de clientes (RFM)**.

---

## 🎯 1. Problema de Negocio / Desafío de Ingeniería

- **Contexto:** En una plataforma de comercio electrónico, los equipos ejecutivos y de BI requieren consultar continuamente el comportamiento de compra, retención de cohortes y márgenes de ganancia.
- **Desafío:** 
  1. Consultar directamente sobre bases de datos operacionales relacionales (OLTP) genera uniones complejas de decenas de tablas normalizadas (3NF) que degradan el rendimiento transaccional de producción.
  2. Los datos brutos presentan inconsistencias de tipos, claves naturales operacionales volátiles y falta de una dimensión temporal estructurada para análisis de estacionalidad.
  3. No existen comprobaciones automatizadas que garanticen que las ventas no presenten referencias huérfanas o claves duplicadas.
- **Solución:** Arquitectura de almacén de datos dimensional en DuckDB:
  - **Grano (*Grain*):** 1 fila = 1 artículo vendido en una orden transaccional.
  - **Claves Subrogadas (*Surrogate Keys*):** Claves enteras independientes del sistema operacional para optimizar joins.
  - **Consultas Analíticas Vectorizadas:** Consultas en milisegundos con `DATE_TRUNC`, `NTILE(4)`, `SUM() OVER ()` y CTEs legibles.

---

## 🏛️ 2. Modelo de Datos Dimensional (Star Schema)

```text
               ┌─────────────────────────────────┐
               │         dim_customers           │
               ├─────────────────────────────────┤
               │ customer_key (PK - Surrogate)   │
               │ customer_id  (Natural Key)      │
               │ customer_name, country, city    │
               │ segment, signup_date            │
               └───────────────┬─────────────────┘
                               │
                               │ 1:N
                               ▼
┌───────────────────────────┐  ┌─────────────────────────────────┐  ┌───────────────────────────┐
│       dim_products        │  │           fact_orders           │  │         dim_date          │
├───────────────────────────┤  ├─────────────────────────────────┤  ├───────────────────────────┤
│ product_key (PK - Surr.)  │  │ order_item_key  (PK - Surrogate)│  │ date_key    (PK - YYYYMMDD│
│ product_id  (Natural Key) ├──┼▶ product_key    (FK)            │◀─┼─ full_date  (DATE)        │
│ product_name, category    │  │ customer_key    (FK)            │  │ year, quarter, month      │
│ subcategory               │  │ order_date_key  (FK)            │  │ month_name, day           │
│ unit_cost, standard_price │  │ order_id        (Degenerate Dim)│  │ day_of_week, day_name     │
└───────────────────────────┘  │ order_time, payment_method      │  │ is_weekend  (BOOLEAN)     │
                               │ quantity, unit_price            │  └───────────────────────────┘
                               │ gross_amount, discount_amount   │
                               │ net_amount, cost_amount         │
                               │ margin_amount                   │
                               └─────────────────────────────────┘
```

---

## 📁 3. Estructura del Repositorio

```text
ecommerce-analytics-star-schema-duckdb/
├── data/
│   ├── raw/                             # Datos brutos transaccionales (customers, products, orders)
│   └── warehouse/                       # Almacén analítico columnar DuckDB (ecommerce_analytics.duckdb)
├── sql/
│   ├── 01_ddl_schemas.sql               # Definición DDL del Esquema Estrella (tablas fact y dim)
│   ├── 02_transformations.sql           # Pipeline ELT: poblamiento, surrogate keys y métricas
│   ├── 03_cohort_analysis.sql           # Matriz de retención de cohortes con CTEs y Window Functions
│   ├── 04_rfm_and_clv.sql               # Segmentación RFM con NTILE(4) y Customer Lifetime Value
│   └── 05_data_quality_tests.sql        # Pruebas automatizadas de unicidad e integridad referencial
├── notebooks/
│   └── 01_analisis_dimensional_y_reportes.ipynb # Notebook interactivo con visualización Heatmap Seaborn
├── src/
│   ├── generate_raw_data.py             # Generador de datos transaccionales con cohortes realistas
│   ├── build_warehouse.py               # Orquestador del almacén: migraciones, ELT y data quality
│   └── run_notebook.py                  # Ejecutor automatizado headless del notebook
├── requirements.txt                     # Dependencias versionadas
└── README.md                            # Documentación del proyecto
```

---

## 🛠️ 4. Stack Tecnológico

| Herramienta | Rol en el Proyecto |
| :--- | :--- |
| **SQL Avanzado** | DDL dimensional, CTEs de múltiples pasos, funciones de ventana (`NTILE`, `SUM OVER`, `DATE_TRUNC`) |
| **DuckDB 1.5+** | Motor de base de datos analítica columnar OLAP embebido de alto rendimiento |
| **Kimball Methodology** | Principios de modelado dimensional: grano, claves subrogadas, dimensiones degeneradas |
| **Python 3.11+** | Orquestación del pipeline ELT y generación de datasets |
| **Seaborn & Matplotlib** | Visualización de matrices de retención de cohortes (*Heatmap*) y gráficos RFM |

---

## 📊 5. Resultados Analíticos & Consultas de Negocio

### A. Matriz de Retención por Cohortes de Clientes
Mediante `03_cohort_analysis.sql`, agrupamos a los clientes por su mes de adquisición inicial y rastreamos el porcentaje que realiza compras repetidas en los meses siguientes:
- **Tasa de Retención Promedio Mes 1:** ~28.5%
- **Retención Mes 3:** ~21.0%
- Los datos se visualizan como un mapa de calor (*Heatmap*) en el notebook analítico.

### B. Segmentación Estratégica RFM (Recency, Frequency, Monetary)
Utilizando `NTILE(4)` sobre las métricas agregadas de cliente en `04_rfm_and_clv.sql`:
* **Champions (Alto Valor):** Representan el **~43% de los ingresos totales** con alta frecuencia y compra reciente.
* **Clientes Leales:** Clientes recurrentes con compras constantes a lo largo del año.
* **En Riesgo de Fuga:** Clientes que antes compraban frecuentemente pero no han regresado en los últimos 180 días (objetivo prioritario para campañas de reactivación).

### C. Pruebas Automatizadas de Calidad de Datos (*Data Quality*)
El script `05_data_quality_tests.sql` valida automáticamente:
1. **Unicidad:** 0 claves primarias duplicadas en `dim_customers`, `dim_products`, `dim_date` y `fact_orders`.
2. **Integridad Referencial:** 0 claves foráneas huérfanas en la tabla de hechos.
3. **Reglas de Negocio:** 0 cantidades negativas y consistencia matemática estricta (`net_amount = gross_amount - discount_amount`).

---

## 🚀 6. Guía Rápida de Ejecución

### 1. Clonar el repositorio
```bash
git clone https://github.com/<tu-usuario>/ecommerce-analytics-star-schema-duckdb.git
cd ecommerce-analytics-star-schema-duckdb
```

### 2. Instalar dependencias
```bash
pip install -r requirements.txt
```

### 3. Construir el Data Warehouse y ejecutar pruebas
```bash
python src/build_warehouse.py
```

### 4. Abrir el notebook analítico
```bash
jupyter notebook notebooks/01_analisis_dimensional_y_reportes.ipynb
```
*(Nota: El notebook ya se encuentra pre-ejecutado con todos los gráficos y matrices renderizados).*

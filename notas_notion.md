# 🧠 Apuntes para Notion: Semana 3 — Analytics Engineering & Modelado Dimensional
> **Área:** Analytics Engineering & Data Warehousing  
> **Tema:** Esquema Estrella (Kimball), Funciones de Ventana, Análisis de Cohortes y Segmentación RFM  
> **Dificultad:** ⭐⭐⭐☆☆  
> **Tecnologías:** `SQL Avanzado`, `DuckDB`, `Kimball Modeling`, `Pandas`, `Seaborn`  
> **Estado:** 🟢 *Completado & Verificado*

---

## 🎯 1. Elevator Pitch (Para Entrevistas)
> *"En este proyecto de Analytics Engineering diseñé e implementé un modelo de datos dimensional bajo el estándar de Kimball para un e-commerce, migrando datos transaccionales brutos a un esquema estrella optimizado para analítica en DuckDB. Desarrollé un pipeline ELT en SQL puro, implementé pruebas automatizadas de integridad y unicidad, y construí consultas analíticas de alto nivel con funciones de ventana y CTEs para calcular matrices de retención de cohortes y segmentación RFM, reduciendo drásticamente la latencia de consulta para reportes ejecutivos."*

---

## 📋 2. Checklist de Desarrollo Paso a Paso

- [x] **Fase 1: Diseño Conceptual del Almacén**
  - [x] Definir el grano de la tabla de hechos (1 fila = 1 artículo dentro de una orden de compra transaccional).
  - [x] Identificar medidas aditivas y calculadas (monto bruto, descuentos, monto neto, costo y margen de beneficio).
  - [x] Diseñar claves subrogadas (*Surrogate Keys*) enteras para independizarse de los IDs operacionales.
- [x] **Fase 2: Creación de Esquemas (DDL)**
  - [x] Escribir sentencias `CREATE TABLE` para `dim_date`, `dim_customers`, `dim_products` y `fact_orders` (`sql/01_ddl_schemas.sql`).
  - [x] Crear claves foráneas e integridad referencial en DuckDB.
- [x] **Fase 3: Transformación y Carga (ELT)**
  - [x] Escribir consultas SQL que inserten y transformen los datos desde las tablas crudas (`sql/02_transformations.sql`).
  - [x] Generar dimensión de calendario continua de 2023 a 2025 (`generate_series`).
- [x] **Fase 4: Consultas de Negocio de Alto Impacto**
  - [x] Construir la consulta de **Análisis de Cohortes**: agrupar clientes por mes de primera compra y calcular la retención mes a mes usando CTEs y `DATE_TRUNC` (`sql/03_cohort_analysis.sql`).
  - [x] Calcular la segmentación **RFM (Recencia, Frecuencia, Valor Monetario)** usando `NTILE(4)` (`sql/04_rfm_and_clv.sql`).
  - [x] Visualizar la matriz de retención mediante un Heatmap interactivo en Jupyter Notebook.
- [x] **Fase 5: Pruebas de Calidad de Datos (Data Quality)**
  - [x] Comprobar unicidad de claves primarias en dimensiones y hechos (`sql/05_data_quality_tests.sql`).
  - [x] Comprobar ausencia de claves foráneas huérfanas y consistencia matemática de ingresos y márgenes.

---

## 💡 3. Conceptos Técnicos Clave

### A. Grano de la Tabla de Hechos (*Grain*)
* Es la regla sagrada de Kimball: **¿Qué representa exactamente una fila individual en la tabla de hechos?**
* En este proyecto, el grano es a nivel de **línea de artículo por orden** (`order_line_id`). Si se intentara mezclar el total de la orden con las líneas de productos, las sumas de ingresos se duplicarían al hacer agrupaciones por categoría.

### B. Claves Subrogadas vs Claves Naturales
* **Clave Natural:** El identificador del sistema operacional (ej. `CUST-00042`, `ORD-10023`). Son propensas a cambios, formatos alfanuméricos ineficientes para joins o reasignaciones en el backend.
* **Clave Subrogada:** Un entero (`customer_key`, `product_key`) autoincremental gestionado por el Data Warehouse. Hace que los `JOINs` sean operaciones vectorizadas de enteros ultra-rápidas y permite gestionar dimensiones que cambian lentamente (*Slowly Changing Dimensions*).

### C. Funciones de Ventana en Analítica: `NTILE(n)` vs `DENSE_RANK()`
* `NTILE(4)` divide el conjunto ordenado de filas en 4 grupos de tamaño idéntico (cuartiles). Es ideal para segmentaciones cuantitativas como RFM.
* `DATE_TRUNC('month', date)` normaliza cualquier fecha al primer día del mes a las 00:00:00, facilitando agrupaciones de series de tiempo.

---

## 🎤 4. Preguntas Típicas de Entrevista Técnica

### P1: *"¿Cuál es la diferencia entre un Esquema Estrella y un Esquema Copo de Nieve (Snowflake)?"*
> **Respuesta recomendada:** *"En un Esquema Estrella, las dimensiones están completamente desnormalizadas (un solo nivel de tablas alrededor de la tabla de hechos), lo que minimiza la cantidad de JOINs y optimiza la velocidad de consulta en BI y motores columnares. En un Esquema Copo de Nieve, las dimensiones se normalizan en subtablas (ej. `dim_products` se divide en `dim_categories` y `dim_subcategories`), lo que ahorra algo de espacio de almacenamiento pero añade complejidad y latencia a las consultas analíticas."*

### P2: *"¿Por qué realizar las transformaciones en el Data Warehouse (ELT) en lugar de hacerlo antes de cargar (ETL clásico)?"*
> **Respuesta recomendada:** *"Con motores modernos columnares y vectorizados como DuckDB, Snowflake o BigQuery, la capacidad de procesamiento del almacén es órdenes de magnitud superior a la de un script intermediario de Python. El paradigma ELT permite volcar los datos crudos rápidamente y realizar todas las transformaciones, limpiezas y pruebas de calidad usando SQL declarativo altamente optimizado y paralelizado."*

### P3: *"¿Cómo aseguras la calidad de los datos en este almacén?"*
> **Respuesta recomendada:** *"Implementé una suite de pruebas de integridad referencial y unicidad en SQL (`05_data_quality_tests.sql`) que se ejecuta automáticamente tras la carga. Cada prueba cuantifica si existen claves primarias duplicadas, claves foráneas huérfanas o transgresiones a las reglas de negocio (como cantidades negativas o márgenes matemáticamente inconsistentes), garantizando 0 registros defectuosos antes de que los reportes de BI consuman los datos."*

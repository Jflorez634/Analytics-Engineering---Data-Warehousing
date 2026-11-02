"""
build_warehouse.py
Orquestador del Data Warehouse en DuckDB:
1. Crea la base de datos persistente data/warehouse/ecommerce_analytics.duckdb
2. Ejecuta el DDL del Esquema Estrella (sql/01_ddl_schemas.sql)
3. Ejecuta el pipeline ELT de transformación (sql/02_transformations.sql)
4. Ejecuta las pruebas automatizadas de calidad de datos (sql/05_data_quality_tests.sql)
5. Muestra métricas de validación y resumen financiero
"""

import os
import sys
import time
import duckdb
import pandas as pd

# Fix para caracteres especiales en consola Windows
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WAREHOUSE_DIR = os.path.join(BASE_DIR, "data", "warehouse")
DB_PATH = os.path.join(WAREHOUSE_DIR, "ecommerce_analytics.duckdb")
SQL_DIR = os.path.join(BASE_DIR, "sql")

os.makedirs(WAREHOUSE_DIR, exist_ok=True)

def read_sql_file(filename: str) -> str:
    path = os.path.join(SQL_DIR, filename)
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def main():
    print("=" * 70)
    print("🚀 INICIANDO CONSTRUCCIÓN DEL DATA WAREHOUSE DIMENSIONAL (KIMBALL)")
    print("=" * 70)
    start_time = time.time()

    # Si ya existe la base de datos previa, la eliminamos para reconstrucción limpia
    if os.path.exists(DB_PATH):
        try:
            os.remove(DB_PATH)
            print(" -> Base de datos anterior purgada para reconstrucción limpia.")
        except Exception:
            pass

    # Conectar a DuckDB
    con = duckdb.connect(DB_PATH)
    print(f" -> Conexión establecida con DuckDB: {DB_PATH}")

    # 1. Ejecutar DDL
    print("\n[FASE 1] Ejecutando DDL (01_ddl_schemas.sql)...")
    ddl_sql = read_sql_file("01_ddl_schemas.sql")
    con.execute(ddl_sql)
    print(" ✅ Tablas creadas: dim_date, dim_customers, dim_products, fact_orders")

    # 2. Ejecutar ELT
    print("\n[FASE 2] Ejecutando Pipeline ELT (02_transformations.sql)...")
    # Asegurar que el CWD para lectura de CSVs sea la raíz del proyecto semana_03
    os.chdir(BASE_DIR)
    elt_sql = read_sql_file("02_transformations.sql")
    con.execute(elt_sql)
    print(" ✅ Datos extraídos de data/raw/ y cargados en el Esquema Estrella.")

    # 3. Reporte de conteo de filas
    dim_date_count = con.execute("SELECT COUNT(*) FROM dim_date").fetchone()[0]
    dim_cust_count = con.execute("SELECT COUNT(*) FROM dim_customers").fetchone()[0]
    dim_prod_count = con.execute("SELECT COUNT(*) FROM dim_products").fetchone()[0]
    fact_orders_count = con.execute("SELECT COUNT(*) FROM fact_orders").fetchone()[0]

    print("\n📊 REGISTROS EN EL ALMACÉN DE DATOS:")
    print(f"  • dim_date:       {dim_date_count:>6} días calendarios")
    print(f"  • dim_customers:  {dim_cust_count:>6} clientes")
    print(f"  • dim_products:   {dim_prod_count:>6} productos")
    print(f"  • fact_orders:    {fact_orders_count:>6} líneas de hechos transaccionales")

    # 4. Pruebas automatizadas de Calidad de Datos
    print("\n[FASE 3] Ejecutando Pruebas de Calidad de Datos (05_data_quality_tests.sql)...")
    dq_sql = read_sql_file("05_data_quality_tests.sql")
    dq_results = con.execute(dq_sql).fetchdf()

    total_failures = dq_results["failed_records"].sum()
    print("-" * 70)
    print(f"{'Prueba de Calidad':<45} | {'Registros Fallidos':<18} | {'Estado':<8}")
    print("-" * 70)
    for _, row in dq_results.iterrows():
        status = "PASSED ✅" if row["failed_records"] == 0 else "FAILED ❌"
        print(f"{row['test_name']:<45} | {row['failed_records']:<18} | {status}")
    print("-" * 70)

    if total_failures == 0:
        print(" 🎉 ¡Todas las pruebas de integridad y unicidad pasaron exitosamente!")
    else:
        print(f" ⚠️ Advertencia: se detectaron {total_failures} inconsistencias de datos.")

    # 5. Métricas financieras globales
    fin_summary = con.execute("""
        SELECT
            ROUND(SUM(gross_amount), 2) AS total_gross_revenue,
            ROUND(SUM(discount_amount), 2) AS total_discounts,
            ROUND(SUM(net_amount), 2) AS total_net_revenue,
            ROUND(SUM(cost_amount), 2) AS total_cogs,
            ROUND(SUM(margin_amount), 2) AS total_gross_profit,
            ROUND(SUM(margin_amount) * 100.0 / SUM(net_amount), 2) AS gross_margin_pct
        FROM fact_orders
    """).fetchone()

    print("\n💰 RESUMEN FINANCIERO GLOBAL:")
    print(f"  • Ingresos Brutos:    ${fin_summary[0]:,.2f}")
    print(f"  • Descuentos:        -${fin_summary[1]:,.2f}")
    print(f"  • Ingresos Netos:     ${fin_summary[2]:,.2f}")
    print(f"  • Costo de Ventas:   -${fin_summary[3]:,.2f}")
    print(f"  • Margen Bruto:       ${fin_summary[4]:,.2f} ({fin_summary[5]}%)")

    elapsed = time.time() - start_time
    print(f"\n✨ Proceso completado exitosamente en {elapsed:.2f} segundos.")
    print("=" * 70)

    con.close()

if __name__ == "__main__":
    main()

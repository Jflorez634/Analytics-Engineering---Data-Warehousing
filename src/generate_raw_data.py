"""
Script generador de datos transaccionales crudos (OLTP) para el E-commerce.
Genera 3 entidades fuente:
  1. data/raw/raw_customers.csv (1,200 clientes con datos demográficos y fecha de registro)
  2. data/raw/raw_products.csv  (40 productos en diversas categorías con costos unitarios)
  3. data/raw/raw_orders.csv    (12,000 líneas de órdenes a lo largo de 2023 y 2024, con cohortes realistas)
"""

import os
import random
from datetime import datetime, timedelta
import pandas as pd
import numpy as np

# Semilla fija para reproducibilidad
random.seed(42)
np.random.seed(42)

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_DIR = os.path.join(BASE_DIR, "data", "raw")
os.makedirs(RAW_DIR, exist_ok=True)

print("Generando datos transaccionales brutos...")

# ---------------------------------------------------------
# 1. GENERAR CLIENTES (raw_customers.csv)
# ---------------------------------------------------------
n_customers = 1200
countries_cities = [
    ("Colombia", ["Bogotá", "Medellín", "Cali", "Barranquilla"]),
    ("México", ["Ciudad de México", "Guadalajara", "Monterrey", "Puebla"]),
    ("Chile", ["Santiago", "Valparaíso", "Concepción"]),
    ("Perú", ["Lima", "Arequipa", "Trujillo"]),
    ("Argentina", ["Buenos Aires", "Córdoba", "Rosario"])
]

segments = ["Consumer", "Corporate", "Home Office"]
segment_weights = [0.65, 0.25, 0.10]

start_date = datetime(2023, 1, 1)
end_date = datetime(2024, 12, 31)
date_range_days = (end_date - start_date).days

customers_data = []
for cid in range(1, n_customers + 1):
    country, cities = random.choice(countries_cities)
    city = random.choice(cities)
    segment = random.choices(segments, weights=segment_weights)[0]
    # Distribuir altas de clientes en 2023 y 2024
    signup_day_offset = random.randint(0, date_range_days - 60)
    signup_date = start_date + timedelta(days=signup_day_offset)
    
    customers_data.append({
        "customer_id": f"CUST-{cid:05d}",
        "customer_name": f"Customer_{cid}",
        "country": country,
        "city": city,
        "segment": segment,
        "signup_date": signup_date.strftime("%Y-%m-%d")
    })

df_customers = pd.DataFrame(customers_data)
customers_csv = os.path.join(RAW_DIR, "raw_customers.csv")
df_customers.to_csv(customers_csv, index=False)
print(f" -> Creado: {customers_csv} ({len(df_customers)} filas)")

# ---------------------------------------------------------
# 2. GENERAR PRODUCTOS (raw_products.csv)
# ---------------------------------------------------------
categories = {
    "Technology": [
        ("Wireless Headphones", "Audio", 45.0, 89.99),
        ("Mechanical Keyboard", "Accessories", 35.0, 75.50),
        ("Gaming Mouse", "Accessories", 20.0, 49.99),
        ("USB-C Hub", "Cables & Hubs", 15.0, 34.99),
        ("4K Monitor 27in", "Displays", 160.0, 279.00),
        ("Webcam 1080p", "Cameras", 28.0, 59.99),
        ("Bluetooth Speaker", "Audio", 30.0, 65.00),
        ("External SSD 1TB", "Storage", 55.0, 109.99)
    ],
    "Office Supplies": [
        ("Ergonomic Desk Chair", "Furniture", 85.0, 189.00),
        ("Standing Desk Converter", "Furniture", 70.0, 149.50),
        ("Desk Pad Mat", "Desk Accessories", 8.0, 22.00),
        ("Monitor Arm Stand", "Mounts", 22.0, 49.90),
        ("LED Desk Lamp", "Lighting", 14.0, 32.50),
        ("Cable Management Box", "Organizers", 6.0, 16.99),
        ("Notebook Leather Cover", "Stationery", 9.0, 24.00),
        ("Fountain Pen Set", "Stationery", 12.0, 35.00)
    ],
    "Apparel & Merch": [
        ("Developer Hoodie", "Outerwear", 22.0, 54.99),
        ("Tech Conference T-Shirt", "T-Shirts", 9.0, 24.50),
        ("Canvas Backpack", "Bags", 28.0, 68.00),
        ("Insulated Water Bottle", "Drinkware", 8.0, 21.99),
        ("Thermal Coffee Mug", "Drinkware", 10.0, 25.00),
        ("Beanie Hat", "Hats", 5.0, 15.00),
        ("Tech Laptop Sleeve", "Accessories", 11.0, 26.90),
        ("Cotton Socks Pack", "Apparel", 4.0, 12.00)
    ]
}

products_data = []
pid = 1
for cat, subcat_items in categories.items():
    for name, subcat, cost, price in subcat_items:
        products_data.append({
            "product_id": f"PROD-{pid:04d}",
            "product_name": name,
            "category": cat,
            "subcategory": subcat,
            "unit_cost": cost,
            "standard_price": price
        })
        pid += 1

df_products = pd.DataFrame(products_data)
products_csv = os.path.join(RAW_DIR, "raw_products.csv")
df_products.to_csv(products_csv, index=False)
print(f" -> Creado: {products_csv} ({len(df_products)} filas)")

# ---------------------------------------------------------
# 3. GENERAR ÓRDENES TRANSACCIONALES CON COHORTES (raw_orders.csv)
# ---------------------------------------------------------
# Simularemos compras para cada cliente:
# - Primera compra alrededor de su signup_date
# - Clientes retenidos realizan entre 1 y 6 recompras espaciadas en meses posteriores
orders_data = []
order_counter = 10001
order_item_counter = 1

for _, cust in df_customers.iterrows():
    c_signup = datetime.strptime(cust["signup_date"], "%Y-%m-%d")
    
    # Probabilidad de compra inicial
    n_purchases = np.random.choice([1, 2, 3, 4, 5, 6, 8], p=[0.35, 0.25, 0.15, 0.10, 0.08, 0.05, 0.02])
    
    current_order_date = c_signup + timedelta(days=random.randint(0, 3))
    
    for purchase_idx in range(n_purchases):
        if current_order_date > end_date:
            break
            
        order_id = f"ORD-{order_counter}"
        order_counter += 1
        
        # Cantidad de productos en este pedido (1 a 4 productos)
        items_in_order = random.choices([1, 2, 3, 4], weights=[0.55, 0.28, 0.12, 0.05])[0]
        chosen_prods = df_products.sample(n=items_in_order, replace=False)
        
        payment_method = random.choice(["Credit Card", "PSE / Debit", "PayPal", "Bank Transfer"])
        
        for _, prod in chosen_prods.iterrows():
            qty = random.choices([1, 2, 3, 5], weights=[0.70, 0.20, 0.07, 0.03])[0]
            # Descuento aleatorio (0%, 5%, 10%, 15%)
            discount_pct = random.choices([0.0, 0.05, 0.10, 0.15, 0.20], weights=[0.55, 0.20, 0.15, 0.07, 0.03])[0]
            
            unit_price = prod["standard_price"]
            gross_amount = round(qty * unit_price, 2)
            discount_amount = round(gross_amount * discount_pct, 2)
            net_amount = round(gross_amount - discount_amount, 2)
            
            orders_data.append({
                "order_line_id": f"LINE-{order_item_counter:07d}",
                "order_id": order_id,
                "order_date": current_order_date.strftime("%Y-%m-%d"),
                "order_time": f"{random.randint(8, 22):02d}:{random.randint(0, 59):02d}:{random.randint(0, 59):02d}",
                "customer_id": cust["customer_id"],
                "product_id": prod["product_id"],
                "quantity": qty,
                "unit_price": unit_price,
                "discount_amount": discount_amount,
                "payment_method": payment_method
            })
            order_item_counter += 1
            
        # Próxima compra espaciada entre 20 y 85 días
        days_to_next = random.randint(20, 85)
        current_order_date = current_order_date + timedelta(days=days_to_next)

df_orders = pd.DataFrame(orders_data)
orders_csv = os.path.join(RAW_DIR, "raw_orders.csv")
df_orders.to_csv(orders_csv, index=False)
print(f" -> Creado: {orders_csv} ({len(df_orders)} líneas de órdenes)")
print("¡Generación de datos transaccionales completada con éxito!")

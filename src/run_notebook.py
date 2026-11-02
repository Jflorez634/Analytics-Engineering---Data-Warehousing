"""
run_notebook.py
Ejecutor headless del notebook con nbclient para pre-renderizar los gráficos
y salidas en el archivo .ipynb.
"""

import os
import sys
import nbformat
from nbclient import NotebookClient

# Fix UTF-8 en Windows
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NB_PATH = os.path.join(BASE_DIR, "notebooks", "01_analisis_dimensional_y_reportes.ipynb")

print("Ejecutando notebook de la Semana 3...")
with open(NB_PATH, "r", encoding="utf-8") as f:
    nb = nbformat.read(f, as_version=4)

client = NotebookClient(
    nb, 
    timeout=600, 
    kernel_name="python3", 
    resources={"metadata": {"path": os.path.join(BASE_DIR, "notebooks")}}
)

client.execute()

with open(NB_PATH, "w", encoding="utf-8") as f:
    nbformat.write(nb, f)

print("✅ Notebook ejecutado y guardado con todas las salidas pre-renderizadas.")

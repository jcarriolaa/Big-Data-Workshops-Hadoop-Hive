#!/usr/bin/env python3
"""Genera los datasets de ventas por grupo (data/ventas/ventas_G1.csv ... ventas_G4.csv).

Uso:
    python3 scripts/generar_ventas.py            # genera los 4 grupos
    python3 scripts/generar_ventas.py --grupo G2 # genera solo uno
    python3 scripts/generar_ventas.py --filas 120000

Cada grupo usa una semilla fija, así que el archivo es reproducible: el mismo comando
produce exactamente el mismo CSV. Solo usa la biblioteca estándar de Python.
"""
import argparse
import csv
import os
import random
from datetime import date, timedelta

PAISES = {
    "Guatemala": ["Ciudad de Guatemala", "Quetzaltenango", "Antigua Guatemala", "Escuintla"],
    "El Salvador": ["San Salvador", "Santa Ana", "San Miguel"],
    "Honduras": ["Tegucigalpa", "San Pedro Sula"],
    "Costa Rica": ["San Jose", "Alajuela"],
    "Mexico": ["Ciudad de Mexico", "Guadalajara", "Monterrey"],
    "Panama": ["Ciudad de Panama"],
}

PRODUCTOS = {
    "Electronica": [("Audifonos", 349.90), ("Telefono", 4200.00), ("Tablet", 2800.00), ("Bocina", 899.00)],
    "Hogar": [("Cafetera", 650.00), ("Licuadora", 480.00), ("Lampara", 210.00)],
    "Ropa": [("Camisa", 180.00), ("Pantalon", 260.00), ("Zapatos", 520.00)],
    "Alimentos": [("Cafe", 95.00), ("Chocolate", 45.00), ("Miel", 70.00)],
    "Deportes": [("Balon", 150.00), ("Bicicleta", 3900.00), ("Mancuernas", 320.00)],
}

CANALES = ["tienda", "web", "app"]
SEMILLAS = {"G1": 101, "G2": 202, "G3": 303, "G4": 404}


def generar(grupo: str, filas: int, destino: str) -> None:
    rnd = random.Random(SEMILLAS[grupo])
    # Cada grupo tiene pesos distintos por pais y canal para que los resultados no coincidan.
    paises = list(PAISES)
    pesos_pais = [rnd.randint(1, 10) for _ in paises]
    pesos_canal = [rnd.randint(1, 5) for _ in CANALES]
    categorias = list(PRODUCTOS)
    inicio = date(2024, 1, 1)

    with open(destino, "w", newline="") as f:
        # lineterminator="\n": el default de csv es "\r\n" y Hive dejaría el "\r" pegado a la última columna.
        w = csv.writer(f, lineterminator="\n")
        w.writerow(["id_venta", "fecha", "pais", "ciudad", "categoria", "producto",
                    "cantidad", "precio_unitario", "canal"])
        for i in range(1, filas + 1):
            pais = rnd.choices(paises, weights=pesos_pais)[0]
            ciudad = rnd.choice(PAISES[pais])
            categoria = rnd.choice(categorias)
            producto, base = rnd.choice(PRODUCTOS[categoria])
            precio = round(base * rnd.uniform(0.9, 1.15), 2)
            cantidad = rnd.choices([1, 2, 3, 4, 5], weights=[50, 25, 13, 8, 4])[0]
            fecha = inicio + timedelta(days=rnd.randint(0, 365))
            canal = rnd.choices(CANALES, weights=pesos_canal)[0]
            w.writerow([i, fecha.isoformat(), pais, ciudad, categoria, producto,
                        cantidad, f"{precio:.2f}", canal])

    tam_mb = os.path.getsize(destino) / (1024 * 1024)
    print(f"{destino}: {filas} filas, {tam_mb:.1f} MB")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--grupo", choices=SEMILLAS, help="genera solo este grupo")
    ap.add_argument("--filas", type=int, default=75000, help="filas por archivo (default 75000, ~5 MB)")
    ap.add_argument("--salida", default=os.path.join(os.path.dirname(__file__), "..", "data", "ventas"))
    args = ap.parse_args()

    os.makedirs(args.salida, exist_ok=True)
    for g in ([args.grupo] if args.grupo else SEMILLAS):
        generar(g, args.filas, os.path.join(args.salida, f"ventas_{g}.csv"))

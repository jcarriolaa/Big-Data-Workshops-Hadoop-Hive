# Datasets de ventas por grupo

Cada grupo trabaja con **su propio archivo**: `ventas_G1.csv`, `ventas_G2.csv`, `ventas_G3.csv` o `ventas_G4.csv`.
Los cuatro tienen la misma estructura pero datos distintos, así que los resultados de las consultas
y la ubicación de los bloques no coinciden entre grupos.

Columnas:

| Columna | Tipo | Ejemplo |
|---|---|---|
| `id_venta` | INT | 1 |
| `fecha` | STRING (`YYYY-MM-DD`) | 2024-03-15 |
| `pais` | STRING | Guatemala |
| `ciudad` | STRING | Quetzaltenango |
| `categoria` | STRING | Electronica |
| `producto` | STRING | Audifonos |
| `cantidad` | INT | 2 |
| `precio_unitario` | DECIMAL(10,2) | 349.90 |
| `canal` | STRING | web / tienda / app |

Cada archivo pesa alrededor de 5 MB. Como el taller configura bloques de HDFS de 1 MB, un archivo
se parte en 5 o 6 bloques, suficientes para ver cómo HDFS los reparte entre DataNodes.

Los archivos se generaron con `scripts/generar_ventas.py` (semilla fija por grupo, así que son reproducibles).

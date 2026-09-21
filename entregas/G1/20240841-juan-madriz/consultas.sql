-- ============================================================
-- Taller Hadoop + Hive  |  Grupo 1  |  20240841 Juan Madriz
-- Todo lo ejecutado en beeline, en orden.
-- ============================================================

-- ---------- PASO 7: tablas externas (schema-on-read) ----------

CREATE EXTERNAL TABLE empleados (
  id            INT,
  nombre        STRING,
  departamento  STRING,
  salario       INT,
  pais          STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/empleados/'
TBLPROPERTIES ('skip.header.line.count'='1');

CREATE EXTERNAL TABLE word_count (
  linea STRING
)
STORED AS TEXTFILE
LOCATION '/datasets/word_count/';

CREATE EXTERNAL TABLE ventas (
  id_venta         INT,
  fecha            STRING,
  pais             STRING,
  ciudad           STRING,
  categoria        STRING,
  producto         STRING,
  cantidad         INT,
  precio_unitario  DECIMAL(10,2),
  canal            STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/ventas/'
TBLPROPERTIES ('skip.header.line.count'='1');

-- ---------- PASO 8: consultas ----------

-- Filtro
SELECT nombre, departamento, salario
FROM empleados
WHERE departamento = 'Ingenieria' AND salario > 6000;

-- Agregacion
SELECT departamento, COUNT(*) AS personas, ROUND(AVG(salario), 2) AS salario_promedio
FROM empleados
GROUP BY departamento
ORDER BY salario_promedio DESC;

-- Sobre el archivo grande: Hive lee los 6 bloques
SELECT COUNT(*) FROM ventas;          -- 75000

-- Word count en SQL: mismo resultado que WordCount.java del Paso 5
SELECT palabra, COUNT(*) AS total
FROM word_count LATERAL VIEW explode(split(linea, ' ')) t AS palabra
GROUP BY palabra
ORDER BY total DESC, palabra
LIMIT 5;
-- guarda 6 | el 5 | bloques 4 | cada 4 | datanode 4   <- identico a part-r-00000

-- Plan de ejecucion: Hive genera una fase Map y una Reduce
EXPLAIN SELECT pais, SUM(cantidad * precio_unitario) FROM ventas GROUP BY pais;
-- Vertex dependency in root stage
-- Reducer 2 <- Map 1 (SIMPLE_EDGE)

-- ---------- MINI-RETO DEL GRUPO (E4) ----------
-- Reto asignado al grupo 1: A
-- Pregunta: ventas totales (cantidad * precio_unitario) por pais, de mayor a menor.
--           Cual pais concentra mas ventas?
-- Respuesta: Guatemala, con Q33,070,879.93 en 19,443 ventas.

-- === RETO A (ASIGNADO) -> evidencia E4 ===
SELECT pais,
       ROUND(SUM(cantidad * precio_unitario), 2) AS total_ventas,
       COUNT(*) AS num_ventas
FROM ventas
GROUP BY pais
ORDER BY total_ventas DESC;
-- Guatemala    33070879.93  19443   <- concentra mas ventas
-- Honduras     30245158.73  17713
-- Mexico       26893624.89  15913
-- Costa Rica   20236844.05  11915
-- El Salvador  13590161.66   8061
-- Panama        3514714.55   1955

-- --- Los otros tres retos, ejecutados como referencia (no son el asignado) ---

-- === RETO B: top 5 productos por unidades ===
SELECT producto, SUM(cantidad) AS unidades
FROM ventas GROUP BY producto ORDER BY unidades DESC LIMIT 5;
-- Cafe 9753 | Chocolate 9665 | Pantalon 9658 | Licuadora 9648 | Lampara 9619

-- === RETO C: ventas totales por mes ===
SELECT substr(fecha, 1, 7) AS mes,
       ROUND(SUM(cantidad * precio_unitario), 2) AS total_ventas,
       COUNT(*) AS num_ventas
FROM ventas GROUP BY substr(fecha, 1, 7) ORDER BY total_ventas DESC;
-- mejor 2024-01 (11348526.86) | peor 2024-02 (9886106.83)

-- === RETO D: ticket promedio por canal ===
SELECT canal,
       ROUND(AVG(cantidad * precio_unitario), 2) AS ticket_promedio,
       COUNT(*) AS num_ventas,
       ROUND(SUM(cantidad * precio_unitario), 2) AS total_ventas
FROM ventas GROUP BY canal ORDER BY ticket_promedio DESC;
-- web 1708.96 (12532) | tienda 1708.23 (31310) | app 1689.78 (31158)

-- Mini-reto del Paso 8 (README): ciudad con mas ventas
SELECT ciudad, ROUND(SUM(cantidad * precio_unitario), 2) AS total
FROM ventas GROUP BY ciudad ORDER BY total DESC LIMIT 1;

-- ---------- PASO 9: DROP de tabla externa vs administrada (E5) ----------

-- Tabla ADMINISTRADA: sin EXTERNAL, Hive copia los datos a SU carpeta (el warehouse)
CREATE TABLE empleados_admin AS SELECT * FROM empleados;
DESCRIBE FORMATTED empleados_admin;
-- Location:   hdfs://namenode:9000/user/hive/warehouse/empleados_admin
-- Owner:      hive          <- lo escribio Hive, no hadoop
-- Table Type: EXTERNAL_TABLE con external.table.purge=TRUE
--   NOTA: el README espera MANAGED_TABLE. Hive 4 aplica por defecto un
--   "metadata transformer" que convierte las administradas no transaccionales
--   en externas con purga. Pusimos metastore.metadata.transformer.class vacia
--   en hive-site.xml, pero Hive interpreta el valor vacio como "undefined" y
--   usa el transformador por defecto igual. El comportamiento es el mismo:
--   purge=TRUE => el DROP borra los datos. Solo cambia la etiqueta.

-- El experimento
DROP TABLE empleados_admin;   -- se lleva sus datos del warehouse
DROP TABLE empleados;         -- solo borra metadatos; el CSV sigue en /datasets
SHOW TABLES;

-- Resultado observado:
--   warehouse ANTES:   /user/hive/warehouse/empleados_admin/000000_0  (404 bytes)
--   warehouse DESPUES: vacio                       <- datos BORRADOS
--   /datasets/empleados/empleados.csv: 440 bytes, timestamp 20:59 del Paso 4
--                                                  <- datos INTACTOS

-- Recrear la externa: los datos "reaparecen" porque nunca se fueron de HDFS
CREATE EXTERNAL TABLE empleados (
  id INT, nombre STRING, departamento STRING, salario INT, pais STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/empleados/'
TBLPROPERTIES ('skip.header.line.count'='1');

SELECT COUNT(*) FROM empleados;   -- 10

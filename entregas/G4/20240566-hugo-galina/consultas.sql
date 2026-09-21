-- =====================================================================
-- consultas.sql — Taller Hadoop y Hive, Grupo G4
-- Todas las sentencias corridas en beeline a lo largo del taller,
-- en el orden en que se ejecutaron.
-- =====================================================================


-- =====================================================================
-- Paso 7: Creación de las tablas externas
-- =====================================================================

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

-- Checkpoints del Paso 7
SHOW TABLES;

SELECT * FROM empleados LIMIT 3;

DESCRIBE FORMATTED empleados;

SELECT COUNT(*) FROM ventas;   -- 75000


-- =====================================================================
-- Paso 8: Consultas
-- =====================================================================

-- Filtro simple
SELECT nombre, departamento, salario
FROM empleados
WHERE departamento = 'Ingenieria' AND salario > 6000;

-- Agregación: promedio de salario por departamento
SELECT departamento, COUNT(*) AS personas, ROUND(AVG(salario), 2) AS salario_promedio
FROM empleados
GROUP BY departamento
ORDER BY salario_promedio DESC;

-- Ventas totales por país (archivo completo, 75000 filas)
SELECT pais, ROUND(SUM(cantidad * precio_unitario), 2) AS total_ventas, COUNT(*) AS num_ventas
FROM ventas
GROUP BY pais
ORDER BY total_ventas DESC;

-- Word count en SQL (LATERAL VIEW + explode), comparado contra MapReduce del Paso 5
SELECT palabra, COUNT(*) AS total
FROM word_count LATERAL VIEW explode(split(linea, ' ')) t AS palabra
GROUP BY palabra
ORDER BY total DESC, palabra
LIMIT 5;

-- Plan de ejecución: confirma que GROUP BY se traduce en Map + Reduce
EXPLAIN SELECT pais, SUM(cantidad * precio_unitario) FROM ventas GROUP BY pais;

-- Mini-reto del Paso 8: ciudad con más ventas en dinero
SELECT ciudad, ROUND(SUM(cantidad * precio_unitario), 2) AS total
FROM ventas
GROUP BY ciudad
ORDER BY total DESC
LIMIT 1;
-- Resultado: Ciudad de Panama, 41,664,608.23


-- =====================================================================
-- Paso 9: Experimento DROP — tabla externa vs. tabla administrada
-- =====================================================================

-- Crear la copia administrada
CREATE TABLE empleados_admin AS SELECT * FROM empleados;
DESCRIBE FORMATTED empleados_admin;
-- Location: hdfs://namenode:9000/user/hive/warehouse/empleados_admin
-- Table Type: MANAGED_TABLE

-- Borrar ambas tablas
DROP TABLE empleados_admin;
DROP TABLE empleados;
SHOW TABLES;

-- Recrear la tabla externa (se necesita para el resto del taller y la defensa oral)
CREATE EXTERNAL TABLE empleados (
  id INT, nombre STRING, departamento STRING, salario INT, pais STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/empleados/'
TBLPROPERTIES ('skip.header.line.count'='1');

SELECT COUNT(*) FROM empleados;   -- 10


-- =====================================================================
-- Mini-reto del grupo (Reto D): ticket promedio por canal
-- =====================================================================

SELECT canal,
       ROUND(AVG(cantidad * precio_unitario), 2) AS ticket_promedio,
       COUNT(*) AS num_ventas
FROM ventas
GROUP BY canal
ORDER BY ticket_promedio DESC;

-- Resultado:
-- app     | 1719.47 | 25185
-- web     | 1710.87 | 37298
-- tienda  | 1642.78 | 12517
-- Interpretación: "app" tiene el ticket promedio más alto, aunque "web"
-- concentra la mayor cantidad de ventas.
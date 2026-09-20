-- =============================================================================
-- Taller Hadoop y Hive en Docker - Consultas Hive (G4)
-- Estudiante: Jonatan Aguilar (Carné: 20240565)
-- Grupo: G4
-- =============================================================================

-- 1. Creación de tablas externas sobre datos existentes en HDFS
CREATE EXTERNAL TABLE IF NOT EXISTS empleados (
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

CREATE EXTERNAL TABLE IF NOT EXISTS word_count (
  linea STRING
)
STORED AS TEXTFILE
LOCATION '/datasets/word_count/';

CREATE EXTERNAL TABLE IF NOT EXISTS ventas (
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

SHOW TABLES;

-- 2. Consultas de exploración y verificación
SELECT * FROM empleados LIMIT 3;

SELECT nombre, departamento, salario
FROM empleados
WHERE departamento = 'Ingenieria' AND salario > 6000;

SELECT departamento, COUNT(*) AS personas, ROUND(AVG(salario), 2) AS salario_promedio
FROM empleados
GROUP BY departamento
ORDER BY salario_promedio DESC;

SELECT COUNT(*) FROM ventas;

-- 3. Word Count en SQL
SELECT palabra, COUNT(*) AS total
FROM word_count LATERAL VIEW explode(split(linea, ' ')) t AS palabra
GROUP BY palabra
ORDER BY total DESC, palabra
LIMIT 5;

-- 4. Plan de ejecución (EXPLAIN)
EXPLAIN SELECT pais, SUM(cantidad * precio_unitario) FROM ventas GROUP BY pais;

-- 5. Mini-reto D (Grupo 4)
-- Pregunta de negocio: Ticket promedio por canal (tienda, web, app) y número de ventas por canal.
-- ¿Qué canal tiene el ticket más alto?
SELECT
  canal,
  ROUND(AVG(cantidad * precio_unitario), 2) AS ticket_promedio,
  COUNT(*) AS num_ventas,
  ROUND(SUM(cantidad * precio_unitario), 2) AS total_ventas
FROM ventas
GROUP BY canal
ORDER BY ticket_promedio DESC;

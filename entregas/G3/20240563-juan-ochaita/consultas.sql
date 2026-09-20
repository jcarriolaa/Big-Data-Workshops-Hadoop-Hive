
-- Ingresar a la terminal de HiveServer2
-- docker exec -it hiveserver2 beeline -u jdbc:hive2://localhost:10000

-- Crear tablas 
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

-- Mostrar tablas

SHOW TABLES;

-- 

SELECT * FROM empleados LIMIT 3;

--

SELECT nombre, departamento, salario
FROM empleados
WHERE departamento = 'Ingenieria' AND salario > 6000;

--

SELECT departamento, COUNT(*) AS personas, ROUND(AVG(salario), 2) AS salario_promedio
FROM empleados
GROUP BY departamento
ORDER BY salario_promedio DESC;

--

SELECT COUNT(*) FROM ventas;

--

SELECT pais, ROUND(SUM(cantidad * precio_unitario), 2) AS total_ventas, COUNT(*) AS num_ventas
FROM ventas
GROUP BY pais
ORDER BY total_ventas DESC;

--

SELECT palabra, COUNT(*) AS total
FROM word_count LATERAL VIEW explode(split(linea, ' ')) t AS palabra
GROUP BY palabra
ORDER BY total DESC, palabra
LIMIT 5;

--

EXPLAIN SELECT pais, SUM(cantidad * precio_unitario) FROM ventas GROUP BY pais;

--

CREATE TABLE empleados_admin AS SELECT * FROM empleados;

ALTER TABLE empleados_admin SET TBLPROPERTIES (
  'EXTERNAL'='FALSE',
  'external.table.purge'='FALSE',
  'TRANSLATED_TO_EXTERNAL'='FALSE'
);

DESCRIBE FORMATTED empleados_admin;

--

DROP TABLE empleados_admin;
DROP TABLE empleados;
SHOW TABLES;

--

CREATE EXTERNAL TABLE empleados (
  id INT, nombre STRING, departamento STRING, salario INT, pais STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/empleados/'
TBLPROPERTIES ('skip.header.line.count'='1');

SELECT COUNT(*) FROM empleados;

-- MINI RETO:

SELECT
  substr(fecha, 1, 7) AS mes,
  SUM(cantidad * precio_unitario) AS ventas_totales
FROM ventas
GROUP BY substr(fecha, 1, 7)
ORDER BY ventas_totales DESC;
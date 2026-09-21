-- Bitácora Hadoop/Hive - Fabiola Deras Gutierrez - Grupo G2

-- Paso 7
CREATE EXTERNAL TABLE empleados (
  id INT, nombre STRING, departamento STRING, salario INT, pais STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/empleados/'
TBLPROPERTIES ('skip.header.line.count'='1');

CREATE EXTERNAL TABLE ventas (
  id_venta INT, fecha STRING, pais STRING, ciudad STRING, categoria STRING,
  producto STRING, cantidad INT, precio_unitario DECIMAL(10,2), canal STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/ventas/'
TBLPROPERTIES ('skip.header.line.count'='1');

CREATE EXTERNAL TABLE word_count (
  linea STRING
)
STORED AS TEXTFILE
LOCATION '/datasets/word_count/';

SHOW TABLES;

SELECT * FROM empleados LIMIT 3;

DESCRIBE FORMATTED empleados;

-- Paso 8

-- Filtro
SELECT nombre, departamento, salario
FROM empleados
WHERE departamento = 'Ingenieria' AND salario > 6000;

-- Agregación
SELECT departamento, COUNT(*) AS personas, ROUND(AVG(salario), 2) AS salario_promedio
FROM empleados
GROUP BY departamento
ORDER BY salario_promedio DESC;

-- Sobre el archivo grande
SELECT COUNT(*) FROM ventas;

-- Consulta de negocio (E4): ventas totales por país
SELECT pais, ROUND(SUM(cantidad * precio_unitario), 2) AS total_ventas, COUNT(*) AS num_ventas
FROM ventas
GROUP BY pais
ORDER BY total_ventas DESC;

-- Word count en SQL
SELECT palabra, COUNT(*) AS total
FROM word_count LATERAL VIEW explode(split(linea, ' ')) t AS palabra
GROUP BY palabra
ORDER BY total DESC, palabra
LIMIT 5;

-- Plan de ejecución (Map/Reduce detrás de la consulta)
EXPLAIN SELECT pais, SUM(cantidad * precio_unitario) FROM ventas GROUP BY pais;

-- Paso 9
CREATE TABLE empleados_admin AS SELECT * FROM empleados;
DESCRIBE FORMATTED empleados_admin;

DROP TABLE empleados_admin;
DROP TABLE empleados;
SHOW TABLES;

-- Se vuelve a crear empleados 
CREATE EXTERNAL TABLE empleados (
  id INT, nombre STRING, departamento STRING, salario INT, pais STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/empleados/'
TBLPROPERTIES ('skip.header.line.count'='1');

SELECT COUNT(*) FROM empleados;

-- Mini-reto del grupo, reto B
SELECT producto, SUM(cantidad) AS unidades_vendidas
FROM ventas
GROUP BY producto
ORDER BY unidades_vendidas DESC
LIMIT 5;

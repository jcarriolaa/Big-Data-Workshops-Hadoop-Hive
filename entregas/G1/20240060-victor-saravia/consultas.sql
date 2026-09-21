-- Tablas externas usadas en el taller.
CREATE EXTERNAL TABLE empleados (
  id INT, nombre STRING, departamento STRING, salario INT, pais STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/empleados/'
TBLPROPERTIES ('skip.header.line.count'='1');

CREATE EXTERNAL TABLE word_count (linea STRING)
STORED AS TEXTFILE
LOCATION '/datasets/word_count/';

CREATE EXTERNAL TABLE ventas (
  id_venta INT, fecha STRING, pais STRING, ciudad STRING, categoria STRING,
  producto STRING, cantidad INT, precio_unitario DECIMAL(10,2), canal STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/ventas/'
TBLPROPERTIES ('skip.header.line.count'='1');

-- Consultas del Paso 8.
SELECT nombre, departamento, salario
FROM empleados
WHERE departamento = 'Ingenieria' AND salario > 6000;

SELECT departamento, COUNT(*) AS personas, ROUND(AVG(salario), 2) AS salario_promedio
FROM empleados
GROUP BY departamento
ORDER BY salario_promedio DESC;

SELECT COUNT(*) AS filas_ventas FROM ventas;

SELECT palabra, COUNT(*) AS total
FROM word_count LATERAL VIEW explode(split(linea, ' ')) t AS palabra
GROUP BY palabra
ORDER BY total DESC, palabra
LIMIT 5;

EXPLAIN SELECT pais, SUM(cantidad * precio_unitario)
FROM ventas
GROUP BY pais;

-- Mini-reto A, grupo G1.
SELECT pais,
       ROUND(SUM(cantidad * precio_unitario), 2) AS total_ventas
FROM ventas
GROUP BY pais
ORDER BY total_ventas DESC;

-- Experimento de tabla administrada frente a externa.
CREATE TABLE empleados_admin AS SELECT * FROM empleados;
DROP TABLE empleados_admin;
DROP TABLE empleados;

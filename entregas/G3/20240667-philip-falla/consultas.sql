-- Paso 7: tablas externas sobre los archivos ya subidos a HDFS

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


-- Paso 8: consultas

SELECT nombre, departamento, salario
FROM empleados
WHERE departamento = 'Ingenieria' AND salario > 6000;

SELECT departamento, COUNT(*) AS personas, ROUND(AVG(salario), 2) AS salario_promedio
FROM empleados
GROUP BY departamento
ORDER BY salario_promedio DESC;

SELECT COUNT(*) FROM ventas;

SELECT pais, ROUND(SUM(cantidad * precio_unitario), 2) AS total_ventas, COUNT(*) AS num_ventas
FROM ventas
GROUP BY pais
ORDER BY total_ventas DESC;

SELECT palabra, COUNT(*) AS total
FROM word_count LATERAL VIEW explode(split(linea, ' ')) t AS palabra
GROUP BY palabra
ORDER BY total DESC, palabra
LIMIT 5;

EXPLAIN SELECT pais, SUM(cantidad * precio_unitario) FROM ventas GROUP BY pais;


-- Paso 9: experimento DROP externa vs administrada

CREATE TABLE empleados_admin AS SELECT * FROM empleados;

DESCRIBE FORMATTED empleados_admin;

-- hdfs dfs -ls -R /user/hive/warehouse   (antes del DROP: empleados_admin/000000_0 con datos)

DROP TABLE empleados_admin;
DROP TABLE empleados;
SHOW TABLES;

-- hdfs dfs -ls /user/hive/warehouse       (después: vacío, la administrada se llevó sus datos)
-- hdfs dfs -ls /datasets/empleados        (después: empleados.csv sigue ahí, la externa no borró nada)

-- Se vuelve a crear la tabla externa (los datos nunca se fueron de HDFS):
CREATE EXTERNAL TABLE empleados (
  id INT, nombre STRING, departamento STRING, salario INT, pais STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/empleados/'
TBLPROPERTIES ('skip.header.line.count'='1');

SELECT COUNT(*) FROM empleados;


-- Mini-reto del grupo G3 (reto C): ventas totales por mes

SELECT substr(fecha, 1, 7) AS mes, ROUND(SUM(cantidad * precio_unitario), 2) AS total_ventas
FROM ventas
GROUP BY substr(fecha, 1, 7)
ORDER BY total_ventas DESC;

-- Resultado: mejor mes 2024-10 (11,300,260.07), peor mes 2024-07 (10,192,715.23)

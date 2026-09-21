-- Paso 6: Verificar conexión
SHOW DATABASES;

-- Paso 7: Crear tabla externa de empleados
CREATE EXTERNAL TABLE empleados (
  id INT,
  nombre STRING,
  departamento STRING,
  salario INT,
  pais STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/empleados/'
TBLPROPERTIES ('skip.header.line.count'='1');

-- Paso 7: Crear tabla externa de WordCount
CREATE EXTERNAL TABLE word_count (
  linea STRING
)
STORED AS TEXTFILE
LOCATION '/datasets/word_count/';

-- Paso 7: Crear tabla externa de ventas
CREATE EXTERNAL TABLE ventas (
  id_venta INT,
  fecha STRING,
  pais STRING,
  ciudad STRING,
  categoria STRING,
  producto STRING,
  cantidad INT,
  precio_unitario DECIMAL(10,2),
  canal STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/ventas/'
TBLPROPERTIES ('skip.header.line.count'='1');

-- Paso 7: Verificar las tablas
SHOW TABLES;

-- Paso 7: Consultar empleados
SELECT *
FROM empleados
LIMIT 3;

-- Paso 7: Ver información de la tabla empleados
DESCRIBE FORMATTED empleados;

-- Paso 8: Filtrar empleados de Ingeniería con salario mayor a 6000
SELECT nombre, departamento, salario
FROM empleados
WHERE departamento = 'Ingenieria'
  AND salario > 6000;

-- Paso 8: Promedio de salario por departamento
SELECT departamento,
       COUNT(*) AS personas,
       ROUND(AVG(salario), 2) AS salario_promedio
FROM empleados
GROUP BY departamento
ORDER BY salario_promedio DESC;

-- Paso 8: Cantidad total de ventas
SELECT COUNT(*)
FROM ventas;

-- Paso 8: Ventas agrupadas por país
SELECT pais,
       ROUND(SUM(cantidad * precio_unitario), 2) AS total_ventas,
       COUNT(*) AS num_ventas
FROM ventas
GROUP BY pais
ORDER BY total_ventas DESC;

-- Paso 8: WordCount usando Hive
SELECT palabra,
       COUNT(*) AS total
FROM word_count
LATERAL VIEW explode(split(linea, ' ')) t AS palabra
GROUP BY palabra
ORDER BY total DESC, palabra
LIMIT 5;

-- Paso 8: Ver el plan de ejecución
EXPLAIN
SELECT pais,
       SUM(cantidad * precio_unitario)
FROM ventas
GROUP BY pais;

-- Mini-reto B: Los 5 productos con más unidades vendidas
SELECT producto,
       SUM(cantidad) AS unidades_vendidas
FROM ventas
GROUP BY producto
ORDER BY unidades_vendidas DESC
LIMIT 5;

-- Reto de la guía: Ciudad con más ventas en dinero
SELECT ciudad,
       ROUND(SUM(cantidad * precio_unitario), 2) AS total
FROM ventas
GROUP BY ciudad
ORDER BY total DESC
LIMIT 1;

-- Paso 9: Crear tabla administrada
CREATE TABLE empleados_admin
AS SELECT *
FROM empleados;

-- Paso 9: Ver información de la tabla administrada
DESCRIBE FORMATTED empleados_admin;

-- Paso 9: Eliminar tabla administrada
DROP TABLE empleados_admin;

-- Paso 9: Eliminar tabla externa
DROP TABLE empleados;

-- Paso 9: Verificar las tablas restantes
SHOW TABLES;

-- Paso 9: Recrear tabla externa de empleados
CREATE EXTERNAL TABLE empleados (
  id INT,
  nombre STRING,
  departamento STRING,
  salario INT,
  pais STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/empleados/'
TBLPROPERTIES ('skip.header.line.count'='1');

-- Paso 9: Verificar cantidad de empleados
SELECT COUNT(*)
FROM empleados;
-- Consultas Hive
-- Ana Sofia Eggenberger - 20240449
-- Grupo 1

-- Consulta de empleados de Ingenieria con salario mayor a 6000
SELECT nombre, salario
FROM empleados
WHERE departamento = 'Ingenieria'
  AND salario > 6000;

-- Salario promedio y cantidad de empleados por departamento
SELECT departamento,
       COUNT(*) AS cantidad,
       AVG(salario) AS salario_promedio
FROM empleados
GROUP BY departamento;

-- WordCount utilizando Hive
SELECT palabra, COUNT(*) AS total
FROM word_count
LATERAL VIEW explode(split(linea, ' ')) t AS palabra
GROUP BY palabra
ORDER BY total DESC, palabra
LIMIT 5;

-- Mini-reto A: ventas totales por pais
SELECT pais,
       ROUND(SUM(cantidad * precio_unitario), 2) AS total_ventas
FROM ventas
GROUP BY pais
ORDER BY total_ventas DESC;

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

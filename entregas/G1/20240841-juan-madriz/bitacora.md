# Bitácora del taller Hadoop y Hive

- **Nombre:** Juan Pablo Madriz
- **Carné:** 20240841
- **Grupo:** G1
- **Mini-reto asignado al grupo:** A
- **Sistema operativo y chip de tu laptop:** macOS 15.7.3, Apple M3 (Rosetta activado para imágenes amd64)

> ⚠️ INSTRUCCIONES DE LLENADO (borrar antes de entregar)
> Debajo de cada captura y de cada pregunta hay viñetas con **los datos reales que salieron en tu máquina**.
> Son insumos, NO la respuesta. Redacta tú la prosa con tus palabras.
> La rúbrica da 18/40 por esto y penaliza respuestas idénticas entre compañeros.

## 1. Evidencias

### E1. NameNode con 3 DataNodes vivos (Paso 10)

![E1](capturas/E1-namenode-3-datanodes.png)

Lo que muestra:
<!-- DATOS: UI en localhost:9870/dfshealth.html#tab-overview · Live Nodes: 3 ·
     Dead Nodes: 0 · Under-Replicated Blocks: 0 · DFS Used 91.47 MB -->

### E2. Ubicación de los bloques del archivo de mi grupo (Paso 10)

![E2](capturas/E2-ubicar-bloques.png)

Lo que muestra:
<!-- DATOS: ventas_G1.csv = 6 bloques (blk_1073741827 a blk_1073741832) ·
     cinco de 1,048,576 B + uno de 24,254 B ·
     827-830 en datanode1+datanode2 · 831-832 en datanode1+datanode3 -->

### E3. Un bloque físico dentro de un DataNode (Paso 4 o 10)

![E3](capturas/E3-bloque-fisico.png)

Lo que muestra:
<!-- DATOS: find en datanode1 -> 8 bloques en
     /data/dfs/data/current/BP-855032210-172.18.0.2-.../current/finalized/subdir0/subdir0/ ·
     head -3 de blk_1073741827 muestra el CSV en texto plano con su encabezado -->

### E4. Resultado de la consulta de negocio de mi grupo (Paso 8)

![E4](capturas/E4-consulta-negocio.png)

Lo que muestra:
<!-- DATOS: reto A, ventas por país · Guatemala 33,070,879.93 (19,443) ·
     Honduras 30,245,158.73 (17,713) · Mexico 26,893,624.89 (15,913) ·
     Costa Rica 20,236,844.05 (11,915) · El Salvador 13,590,161.66 (8,061) ·
     Panama 3,514,714.55 (1,955) · suman 75,000 filas -->

### E5. Warehouse antes y después del `DROP` (Paso 9)

![E5](capturas/E5-drop-antes-despues.png)

Lo que muestra:
<!-- DATOS: ANTES /user/hive/warehouse/empleados_admin/000000_0 (404 B, dueño hive) ·
     DESPUÉS warehouse vacío · /datasets/empleados/empleados.csv sigue con 440 B
     y timestamp 20:59, el mismo del Paso 4 -->

### E6. Clúster con un DataNode apagado (Paso 11)

![E6](capturas/E6-nodo-caido.png)

Lo que muestra:
<!-- DATOS: datanode2 Exited(143) · UI: Live Nodes 2, Dead Nodes 1 ·
     los 6 bloques quedaron en datanode1+datanode3 (antes 4 estaban en datanode2) ·
     fsck: Under-replicated 0, Missing 0, Average block replication 2.0, HEALTHY -->

## 2. Preguntas de comprensión

**1. ¿Qué guarda el NameNode y qué guarda cada DataNode?** Justifícalo con lo que encontraste en `/data/dfs/name` y en `/data/dfs/data`.

<!-- DATOS OBSERVADOS:
  - /data/dfs/name/current en namenode: VERSION, fsimage_0000000000000000000,
    fsimage_...md5, edits_inprogress_..., seen_txid
  - Busqué "blk_*" en el namenode: 0 resultados
  - Busqué "fsimage*" en datanode1: 0 resultados
  - /data/dfs/data en datanode1: archivos blk_<id> + su pareja blk_<id>_<gen>.meta (checksums)
  - Idea a desarrollar: el DataNode no sabe a qué archivo pertenece cada bloque
-->

**2. Con tu salida de E2: ¿cuántos bloques tiene el archivo de tu grupo, en qué DataNodes está cada uno y por qué cada bloque aparece en dos nodos?**

<!-- DATOS OBSERVADOS:
  - 6 bloques: blk_1073741827..832 · 5 x 1,048,576 B + 1 x 24,254 B
  - Suma exacta: 5*1048576 + 24254 = 5,267,134 B = tamaño del archivo
  - 827-830: datanode1 + datanode2 · 831-832: datanode1 + datanode3
  - Dos copias porque dfs.replication=2 Y porque corrí "hdfs dfs -setrep -w 2 /datasets"
    (cambiar el XML solo afecta lo que se escriba después)
  - Nunca dos copias en el mismo nodo: morirían juntas si falla ese disco
  - datanode2 tenía 5 bloques, datanode3 tenía 3: ninguno tiene el archivo completo
-->

**3. ¿En qué se diferencia `hdfs dfs -ls /datasets` de `ls /datasets` dentro del contenedor? ¿Dónde están "de verdad" los bytes del archivo?**

<!-- DATOS OBSERVADOS:
  - En el MISMO contenedor (namenode):
      hdfs dfs -ls /datasets  -> lista empleados, ventas, word_count
      ls /datasets            -> "ls: cannot access /datasets: No such file or directory"
  - Los bytes están en /data/dfs/data de los DataNodes, partidos en bloques
  - /datasets solo existe en el fsimage del NameNode
  - Contraste útil: tras "hdfs dfs -get", el "ls -l /tmp/copia_local.csv" SÍ funciona
-->

**4. ¿Qué pasó con los datos al hacer `DROP TABLE` de la tabla externa y qué pasó con los de la administrada? ¿Por qué esa diferencia importa cuando varios equipos comparten un Data Lake?**

<!-- DATOS OBSERVADOS:
  - Administrada (empleados_admin): datos en /user/hive/warehouse/..., dueño "hive".
    Tras el DROP el warehouse quedó VACÍO.
  - Externa (empleados): datos en /datasets/empleados/. Tras el DROP el CSV sigue
    con 440 B y el MISMO timestamp 20:59 del Paso 4 (ni se tocó).
  - Al recrear la tabla externa, SELECT COUNT(*) devolvió 10 sin ningún INSERT.
  - Nota técnica: Hive 4 etiquetó la administrada como EXTERNAL_TABLE con
    external.table.purge=TRUE (ver sección 4). El comportamiento fue el mismo.
  - Idea a desarrollar: Hive, Spark, Trino y Athena leen los mismos archivos
-->

**5. Al apagar `datanode2`: ¿pudiste seguir leyendo tu archivo? ¿Qué hizo el NameNode después de ~1 minuto? Relaciónalo con la P del teorema CAP.**

<!-- DATOS OBSERVADOS:
  - Leí el archivo completo justo después de apagarlo: 75,001 líneas (75,000 + encabezado)
  - En esa lectura salieron 57 líneas extra de avisos: el cliente intentó datanode2,
    falló y usó la otra copia. En la segunda lectura ya no aparecieron.
  - Tiempo hasta declararlo muerto = 2*recheck + 10*heartbeat = 2*10000 + 10*3000
    = 50,000 ms = 50 segundos (verifiqué con: hdfs getconf -confKey ...)
  - Reparación automática: los 4 bloques que estaban en datanode2 se recrearon en
    datanode3. Resultado: los 6 bloques en datanode1+datanode3.
  - fsck con el nodo muerto: Under-replicated 0, Average block replication 2.0, HEALTHY
  - Idea a desarrollar: la tolerancia a particiones se paga ANTES, en disco
    (5 MB de archivo ocupan 10 MB en el clúster)
-->

**6. `WordCount.java` y la consulta de Hive dan el mismo resultado. ¿Qué gana y qué pierde un equipo que usa Hive en vez de escribir MapReduce a mano?**

<!-- DATOS OBSERVADOS:
  - MapReduce (Paso 5): Map input records=10, Map output records=92,
    Combine 92 -> 49, Reduce output records=49. Salida en part-r-00000.
  - Hive (Paso 8), una sola consulta con LATERAL VIEW explode(split(...)):
    resultado IDÉNTICO -> guarda 6, el 5, bloques 4, cada 4, datanode 4
  - WordCount.java: ~84 líneas de Java, hay que compilar y empaquetar
  - EXPLAIN de Hive mostró: "Reducer 2 <- Map 1 (SIMPLE_EDGE)"
    -> Hive genera igual una fase Map y una Reduce; no reemplaza a MapReduce, lo esconde
  - Idea a desarrollar: qué se pierde en control fino (el combiner, el particionado,
    tipos de datos personalizados) y cuándo sí conviene bajar a código
-->

## 3. Mini-reto del grupo

**Pregunta de negocio (reto A):** Ventas totales (`cantidad * precio_unitario`) por **país**, ordenadas de mayor a menor. ¿Cuál país concentra más ventas?

**Consulta:**

```sql
SELECT pais,
       ROUND(SUM(cantidad * precio_unitario), 2) AS total_ventas,
       COUNT(*) AS num_ventas
FROM ventas
GROUP BY pais
ORDER BY total_ventas DESC;
```

**Resultado (pega la tabla que devolvió beeline):**

```
+--------------+---------------+-------------+
|     pais     | total_ventas  | num_ventas  |
+--------------+---------------+-------------+
| Guatemala    | 33070879.93   | 19443       |
| Honduras     | 30245158.73   | 17713       |
| Mexico       | 26893624.89   | 15913       |
| Costa Rica   | 20236844.05   | 11915       |
| El Salvador  | 13590161.66   | 8061        |
| Panama       | 3514714.55    | 1955        |
+--------------+---------------+-------------+
```

**Interpretación en una frase:**
<!-- DATOS: Guatemala lidera con 33.07 M en 19,443 ventas · Panamá es el menor con
     3.5 M en 1,955 · casi 10x de diferencia · los 6 países suman 75,000 filas ·
     dato extra: por CIUDAD gana Tegucigalpa (15,130,869.97), no una ciudad
     guatemalteca, porque las ventas de Guatemala se reparten entre más ciudades -->

## 4. Problemas que tuve y cómo los resolví (opcional)

**a) Paso 6 — HiveServer2 se colgaba al inicializar el metastore (Apple Silicon)**

`schematool` quedaba bloqueado indefinidamente con CPU al 0.00%. Diagnóstico: el proceso padre
tenía un hilo atascado en `kernel_clone` (dentro de `fork()`) y el hijo tenía un solo hilo en
`futex_wait_queue`, o sea un fork que nunca completó el exec. La traza reveló la causa:
`schematool` usa beeline, beeline usa jline, y jline lanza `stty` en un subproceso para medir el
terminal. Ese `fork()` en un proceso multihilo se bloquea bajo emulación Rosetta, y el contenedor
ni siquiera tiene TTY. Arreglo, agregado al `docker-compose.yml`:

```yaml
      _JAVA_OPTIONS: "-Djline.terminal=jline.UnsupportedTerminal"
```

(Antes probé `-Djdk.lang.Process.launchMechanism=POSIX_SPAWN`, que quitó el cuelgue pero falló con
`NoClassDefFoundError: java.lang.UNIXProcess` porque ese modo necesita el binario `jspawnhelper`.)

**b) Paso 6 — HiveServer2 reintentaba arrancar cada 60 s**

`/tmp/hive/hive.log` decía: `The dir: /tmp/hive on HDFS should be writable. Current permissions
are: rwxr-xr-x`. `hdfs dfs -mkdir` crea con 755 y HiveServer2 exige escritura para "otros".
Lo interesante: pasó **a pesar** de tener `dfs.permissions.enabled=false`, porque esa propiedad
apaga la verificación de **HDFS**, pero Hive lee los bits por su cuenta. Son dos capas distintas.
Arreglo (no está en el README):

```bash
docker exec namenode hdfs dfs -chmod -R 1777 /tmp/hive /user/hive/warehouse
```

**c) Paso 9 — la tabla administrada salió como `EXTERNAL_TABLE`**

El README espera `MANAGED_TABLE`. Verifiqué que `hive-site.xml` sí estaba montado y sí tenía
`metastore.metadata.transformer.class` con `<value></value>`, pero Hive responde que la propiedad
está `undefined`: interpreta el valor vacío como "no configurada" y usa el transformador por
defecto, que en Hive 4 convierte las administradas no transaccionales en externas con purga.
Un `SET` de sesión tampoco funciona porque el transformador se instancia al arrancar el metastore.
El experimento igual demuestra el punto: con `external.table.purge=TRUE` el `DROP` borró los datos.

**d) Paso 5 — el contador `Map output records` no coincidía con el README**

El README dice 75 y me salió 92. Lo verifiqué con `wc -w`: `word_count.txt` tiene 92 palabras y
49 distintas. El README quedó desactualizado (su ejemplo cita un archivo de 551 bytes y el del
repo pesa 522). El `Reduce output records=49` sí coincide.

**e) Paso 3 — `dfsadmin -report | head -12` no muestra `Live datanodes`**

En Hadoop 3.4.1 el informe trae más líneas de cabecera que las del ejemplo del README.
Usé `| grep -A6 "Live datanodes"` en su lugar.

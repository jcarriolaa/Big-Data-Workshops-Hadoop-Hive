# Anexo: ¿y el procesamiento distribuido? YARN

Este anexo es de **lectura**. No hay pasos que ejecutar en clase.

## Lo que sí fue distribuido en el taller y lo que no

Al terminar el Paso 10 tienes **almacenamiento distribuido** de verdad: cada bloque vive en dos
DataNodes distintos y el NameNode coordina. Pero el **cómputo** no fue distribuido:

- El `wordcount` de MapReduce (Paso 5) corrió en **modo local**: mappers y reducers se ejecutaron dentro
  de un solo proceso Java en el contenedor del NameNode. Leyó y escribió en HDFS, pero el trabajo lo
  hizo una sola máquina.
- Las consultas de Hive (Pasos 7 a 9) corrieron con el motor **Tez en modo local**, también dentro de
  un solo contenedor (`hiveserver2`).

Para que un job se reparta entre varias máquinas hace falta un componente más: **YARN**.

## Qué es YARN

YARN (*Yet Another Resource Negotiator*) es el administrador de recursos del clúster Hadoop. Nació en
Hadoop 2 (2013) para separar dos cosas que en Hadoop 1 estaban mezcladas: *quién administra CPU y RAM
del clúster* y *cómo se ejecuta un job MapReduce*. Tiene dos tipos de proceso, igual que HDFS:

| HDFS (almacenamiento) | YARN (cómputo) | Rol |
|---|---|---|
| NameNode | ResourceManager | Uno por clúster. Sabe cuánta CPU y RAM hay libre en cada nodo y decide dónde corre cada tarea |
| DataNode | NodeManager | Uno por nodo. Ejecuta las tareas que le asigna el ResourceManager dentro de **containers** (no son contenedores Docker: son porciones de CPU y RAM) |

Normalmente cada máquina corre **un DataNode y un NodeManager**, y ahí está la idea clave: cuando el
ResourceManager reparte los mappers de un job, intenta ponerlos en la máquina que **ya tiene el bloque**
que ese mapper va a leer. Es el principio de *data locality* del paper de MapReduce: mover el cómputo a
los datos, no los datos al cómputo.

## Qué cambiaría en el taller

1. Dos servicios más en el `docker-compose.yml`: `resourcemanager` (UI en `localhost:8088`) y uno o más
   `nodemanager`.
2. Un archivo `mapred-site.xml` con `mapreduce.framework.name=yarn` (hoy es `local`) y un `yarn-site.xml`
   que apunte al ResourceManager.
3. El mismo comando del Paso 5, sin cambios:
   `hadoop jar hadoop-mapreduce-examples-3.4.1.jar wordcount /datasets/word_count /salida/wordcount`.
   La diferencia se vería en `localhost:8088`: un *application* con sus containers repartidos entre
   los NodeManagers, y en el log, mappers ejecutándose en nodos distintos.
4. Hive también podría usar YARN (`tez.local.mode=false`), y cada consulta aparecería en la misma UI.

Esto suma unos 2 GB de RAM y varios minutos de arranque, por eso no está en la sesión de 80 minutos.
El `docker-compose.yml` con YARN está disponible con el catedrático para quien quiera probarlo en casa.

## Para conectar con el resto del curso

- **Spark** hace lo mismo que MapReduce sobre YARN (o sobre Kubernetes), pero manteniendo los datos
  intermedios en memoria en vez de escribirlos a HDFS entre fase y fase. Por eso es entre 10 y 100
  veces más rápido en cargas iterativas.
- En la nube, **EMR** (AWS), **Dataproc** (GCP) y **HDInsight** (Azure) son exactamente este clúster
  (HDFS + YARN + Hive/Spark) administrado por el proveedor, casi siempre con el almacenamiento movido
  a S3, GCS o ADLS en lugar de HDFS.

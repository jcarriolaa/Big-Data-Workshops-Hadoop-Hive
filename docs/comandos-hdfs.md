# Comandos HDFS: equivalencias con tu sistema de archivos local

HDFS se maneja con `hdfs dfs <comando>`. Los comandos imitan a los de Linux a propósito,
pero **no operan sobre el disco de la máquina donde los escribes**, sino sobre el sistema de archivos
distribuido que administra el NameNode. `hadoop fs` es un alias antiguo que hace lo mismo.

En este taller todos se ejecutan dentro del contenedor del NameNode:

```bash
docker exec namenode hdfs dfs -ls /
```

| Quiero... | En mi laptop (local) | En HDFS |
|---|---|---|
| Listar | `ls -l /datasets` | `hdfs dfs -ls /datasets` |
| Listar recursivo | `ls -R /datasets` | `hdfs dfs -ls -R /datasets` |
| Crear carpeta | `mkdir -p /datasets/ventas` | `hdfs dfs -mkdir -p /datasets/ventas` |
| Copiar hacia adentro | `cp archivo.csv /datasets/` | `hdfs dfs -put archivo.csv /datasets/` |
| Copiar hacia afuera | `cp /datasets/archivo.csv .` | `hdfs dfs -get /datasets/archivo.csv .` |
| Ver contenido | `cat archivo.csv` | `hdfs dfs -cat /datasets/archivo.csv` |
| Ver las primeras líneas | `head archivo.csv` | `hdfs dfs -cat /datasets/archivo.csv \| head` |
| Ver las últimas líneas | `tail archivo.csv` | `hdfs dfs -tail /datasets/archivo.csv` |
| Tamaño | `du -h /datasets` | `hdfs dfs -du -h /datasets` |
| Mover o renombrar | `mv a b` | `hdfs dfs -mv /a /b` |
| Copiar dentro del FS | `cp a b` | `hdfs dfs -cp /a /b` |
| Borrar | `rm archivo` | `hdfs dfs -rm /datasets/archivo` |
| Borrar carpeta | `rm -r carpeta` | `hdfs dfs -rm -r /datasets/carpeta` |
| Permisos | `chmod 644 a` | `hdfs dfs -chmod 644 /a` |
| Espacio libre | `df -h` | `hdfs dfs -df -h` |
| ¿Existe? | `test -d carpeta` | `hdfs dfs -test -d /carpeta` |

## Comandos que NO tienen equivalente local

Estos existen porque HDFS es distribuido:

| Comando | Qué hace |
|---|---|
| `hdfs dfsadmin -report` | Lista los DataNodes, cuántos están vivos y cuánto espacio tiene cada uno |
| `hdfs fsck /ruta -files -blocks -locations` | Muestra los bloques de un archivo y en qué DataNode está cada réplica |
| `hdfs dfs -setrep -w 3 /ruta` | Cambia el factor de replicación de un archivo o carpeta y espera a que se cumpla |
| `hdfs dfs -stat "%r %o" /ruta` | Replicación y tamaño de bloque de un archivo |
| `hdfs getconf -confKey dfs.blocksize` | Lee un valor de configuración efectivo |

## Dos diferencias de fondo

1. **Escribes una vez.** HDFS está pensado para *write-once, read-many*: puedes crear y agregar al final
   (`-appendToFile`), pero no editar en medio de un archivo. Por eso los pipelines de datos
   escriben archivos nuevos en vez de modificar los existentes.
2. **Los bloques son grandes.** Un disco local usa bloques de 4 KB; HDFS usa 128 MB por defecto
   (en este taller lo bajamos a 1 MB para poder verlos con archivos pequeños). Un bloque grande
   significa menos metadatos en el NameNode y lecturas secuenciales largas, que es lo que
   necesita el procesamiento batch.

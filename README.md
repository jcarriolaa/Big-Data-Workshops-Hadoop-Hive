# Taller: Hadoop y Hive en Docker, de un nodo a tres

Curso *Big Data y su Relación con Generative AI*, UFM. Clase 15.

En este taller vas a construir, pieza por pieza y en tu propia laptop, un clúster Hadoop con HDFS y Hive.
Primero con un solo nodo de almacenamiento, después con tres. Al final vas a poder responder, con evidencia
que tú mismo generaste, tres preguntas que en clase solo vimos en teoría:

1. ¿Dónde están físicamente los bytes de un archivo "en HDFS" y quién sabe dónde están?
2. ¿Qué agrega Hive encima de esos archivos y por qué una tabla externa no es lo mismo que una administrada?
3. ¿Qué pasa con tus datos cuando un nodo se apaga?

## Objetivos

- Levantar HDFS y Hive con `docker compose`, entendiendo cada archivo de configuración.
- Distinguir el sistema de archivos local de HDFS y manejar los comandos básicos de HDFS.
- Ubicar cada bloque de un archivo en el DataNode donde vive, y verlo físicamente.
- Ver la diferencia entre procesar con MapReduce y consultar con Hive.
- Crear tablas externas sobre archivos existentes y entender qué pasa al borrarlas.
- Escalar a tres DataNodes, verificar réplicas y observar la recuperación cuando un nodo cae.

## Qué vas a construir

```
      tu laptop (Docker Desktop)
  ┌──────────────────────────────────────────────────────────────────┐
  │                                                                  │
  │   ┌──────────────┐   beeline / SQL    ┌─────────────────┐        │
  │   │  hiveserver2 │◄───────────────────│   tú (terminal) │        │
  │   │  (Hive 4)    │                    └─────────────────┘        │
  │   └──────┬───────┘                            │ hdfs dfs ...     │
  │          │ lee/escribe archivos               ▼                  │
  │          │                          ┌──────────────────┐         │
  │          └─────────────────────────►│     namenode     │  :9870  │
  │                                     │  (mapa de bloques│         │
  │                                     │   NO datos)      │         │
  │                                     └────────┬─────────┘         │
  │                    latidos cada 3 s          │                   │
  │          ┌───────────────────┬───────────────┴──────────┐        │
  │          ▼                   ▼                          ▼        │
  │   ┌────────────┐      ┌────────────┐            ┌────────────┐   │
  │   │ datanode1  │      │ datanode2  │            │ datanode3  │   │
  │   │ blk_..25   │      │ blk_..25   │            │ blk_..26   │   │
  │   │ blk_..26   │      │ blk_..27   │            │ blk_..27   │   │
  │   └────────────┘      └────────────┘            └────────────┘   │
  │        Parte 1              Parte 2 (se agregan en el Paso 10)   │
  └──────────────────────────────────────────────────────────────────┘
```

- **NameNode:** el "índice" de HDFS. Sabe qué archivos existen, en cuántos bloques está partido cada uno y
  en qué DataNode está cada copia. No guarda ni un byte de los datos.
- **DataNode:** el que guarda los bloques en su disco. Le manda un latido al NameNode cada 3 segundos.
- **HiveServer2:** recibe SQL, lo traduce a un plan de ejecución y lee los archivos de HDFS. Hive no guarda
  datos; guarda *metadatos* (qué tabla apunta a qué carpeta y con qué columnas) en su *metastore*.

## Cómo leer esta guía

Cada paso tiene siempre la misma estructura:

1. **Qué vas a hacer y por qué**, en dos o tres líneas.
2. **Código para copiar**, ya probado. Copia el bloque completo.
3. **✅ Checkpoint:** un comando y la salida que debes ver antes de seguir. No avances si no la ves.
4. **❌ Si falla:** los errores típicos de ese paso y cómo arreglarlos.

Algunos pasos terminan con un **mini-reto**. La respuesta está oculta debajo; intenta antes de abrirla.

Convenciones:

- Los comandos son para una terminal: Terminal en Mac, **Git Bash** o PowerShell en Windows, cualquier shell en Linux.
- Todos los comandos se ejecutan **desde la carpeta del repo** (donde está este README).
- `G#` significa tu grupo: `G1`, `G2`, `G3` o `G4`. Sustitúyelo donde aparezca.

## Cómo se trabaja: empieza en clase, termina en casa

El taller **arranca en clase y se termina como tarea**. En los 80 minutos de clase la meta es llegar con HDFS y
Hive funcionando, para que las dudas de instalación y de Docker se resuelvan con el catedrático al lado. Lo que
queda (consultas, experimento de `DROP`, tres nodos y nodo caído) se hace en casa con esta guía. Trabaja con tu
grupo, pero **en tu propia laptop**: la bitácora es individual y en la defensa cada uno demuestra una parte.

| Dónde | Pasos | Meta |
|---|---|---|
| Antes de la clase | 0 | Docker instalado, imágenes descargadas, `check.sh prereq` en verde |
| En clase (80 min) | 1 a 6 | HDFS con un nodo, datos cargados, bloques ubicados, MapReduce corrido, Hive conectado |
| En casa | 7 a 12 | Tablas externas, consultas, experimento `DROP`, tres nodos, nodo caído, limpieza |

Si en clase avanzas más rápido, sigue; si te atrasas, no importa: cada paso tiene su checkpoint y su sección
de errores para que puedas continuar sin ayuda. Si te atoras en casa, anota el paso y el error exacto y
tráelo a la siguiente clase.

## Entregable

El taller se evalúa con una **bitácora individual** (40 %) y una **defensa oral por grupo** (60 %) en la que a
cada integrante le toca demostrar en vivo una parte distinta, en una clase posterior cuya fecha se anuncia en clase. Los detalles, las preguntas y la rúbrica están en
[`docs/entregable.md`](docs/entregable.md). Léelo antes de empezar para saber qué capturas tienes que tomar en el camino.

---

## Paso 0: Prerrequisitos

Hazlo **antes de la clase**. Descargar las imágenes de Docker toma varios minutos y depende de la red;
si lo dejas para la clase, pierdes el primer bloque esperando.

### 0.1 Docker Desktop

1. Instala [Docker Desktop](https://www.docker.com/products/docker-desktop/) para tu sistema.
   - **Windows:** durante la instalación acepta usar **WSL 2**. Reinicia si te lo pide.
   - **Mac con chip Apple (M1/M2/M3/M4):** en *Settings → General* activa
     **"Use Rosetta for x86_64/amd64 emulation on Apple Silicon"**. Las imágenes del taller son `amd64`.
2. Ábrelo y espera a que el ícono de la ballena diga *Docker Desktop is running*.
3. En *Settings → Resources* asigna al menos **6 GB de memoria** (8 GB si puedes) y **2 CPUs**.
   Con un nodo basta con 4 GB, pero en la Parte 2 corren cinco contenedores Java a la vez.
   > En Windows con WSL 2 la memoria se configura en el archivo `%UserProfile%\.wslconfig`:
   > ```
   > [wsl2]
   > memory=8GB
   > ```
   > Guarda, ejecuta `wsl --shutdown` en PowerShell y vuelve a abrir Docker Desktop.

### 0.2 Descargar el repo

Con git:

```bash
git clone https://github.com/jcarriolaa/Big-Data-Workshops-Hadoop-Hive.git
cd Big-Data-Workshops-Hadoop-Hive
```

O sin git: botón verde **Code → Download ZIP** en GitHub, descomprime y entra a la carpeta con `cd`.

### 0.3 Descargar las imágenes

Son dos imágenes oficiales de Apache, con versión fija para que a todos les funcione igual:

```bash
docker pull --platform linux/amd64 apache/hadoop:3.4.1
docker pull --platform linux/amd64 apache/hive:4.0.0
```

Pesan alrededor de 1.5 GB en total. El `--platform linux/amd64` es obligatorio en Mac con chip Apple (las imágenes
no tienen versión `arm64`) y no estorba en Intel ni en Windows.

### ✅ Checkpoint

```bash
bash scripts/check.sh prereq
```

Salida esperada:

```
✅ Docker instalado: Docker version 27.x.x, build ...
✅ Docker Compose v2: 2.x.x
✅ Docker Desktop está corriendo
✅ RAM asignada a Docker: 8 GB
✅ Imagen apache/hadoop:3.4.1 descargada
✅ Imagen apache/hive:4.0.0 descargada

Todo en orden.
```

### ❌ Si falla

| Síntoma | Causa y arreglo |
|---|---|
| `bash: scripts/check.sh: No such file` | No estás en la carpeta del repo. `cd` hasta donde está este README. |
| `docker: command not found` | Docker Desktop no está instalado o la terminal se abrió antes de instalarlo. Cierra y vuelve a abrir la terminal. |
| `Cannot connect to the Docker daemon` | Docker Desktop no está corriendo. Ábrelo y espera a que diga *running*. |
| `RAM asignada a Docker: 2 GB` | Sube la memoria en *Settings → Resources* (o `.wslconfig` en Windows) y reinicia Docker Desktop. |
| `no matching manifest for linux/arm64/v8` al hacer `pull` | Falta `--platform linux/amd64` en el comando. Cópialo completo del punto 0.3. |
| El `pull` se queda colgado | Red lenta o proxy. Reintenta; el `pull` continúa donde se quedó. |
| En Windows: `bash` no existe | Abre **Git Bash** (viene con Git) en vez de CMD. En PowerShell, ejecuta los comandos `docker` directamente y omite `check.sh`. |

---

# Parte 1: HDFS y Hive con un nodo

## Paso 1: Conoce el repo

El repo trae los datos y las herramientas; **los archivos de configuración y el `docker-compose.yml` los
vas a escribir tú** en los siguientes pasos, porque armarlos es la forma de entender qué hace cada pieza.

```
Big-Data-Workshops-Hadoop-Hive/
├── README.md                  <- esta guía
├── data/                      <- datasets (ya listos, no hay que crearlos)
│   ├── empleados/empleados.csv       10 filas: para las primeras consultas
│   ├── word_count/word_count.txt     10 líneas: para MapReduce y Hive
│   └── ventas/ventas_G1.csv ... G4   ~5 MB cada uno: para ver bloques y réplicas
├── scripts/
│   ├── check.sh               <- autovalidación por etapa
│   ├── ubicar_bloques.sh      <- en qué DataNode está cada bloque de un archivo
│   └── generar_ventas.py      <- generador de los CSV de ventas (no hace falta correrlo)
├── ejemplos/WordCount.java    <- MapReduce para LEER, no para compilar
└── docs/
    ├── entregable.md          <- bitácora, preguntas y rúbrica
    ├── comandos-hdfs.md       <- equivalencias local vs. HDFS
    └── anexo-yarn.md          <- lectura: cómo se distribuye el cómputo
```

Crea las carpetas donde irán tus archivos de configuración:

```bash
mkdir -p config/hadoop config/hive
```

### ✅ Checkpoint

```bash
ls data/ventas/
```

```
README.md      ventas_G1.csv  ventas_G2.csv  ventas_G3.csv  ventas_G4.csv
```

Identifica el archivo de **tu grupo**: es el único que vas a subir a HDFS.

---

## Paso 2: Los dos archivos de configuración de HDFS

Hadoop se configura con archivos XML de pares `name`/`value`. Solo necesitas dos:
`core-site.xml` dice **dónde está el NameNode**, y `hdfs-site.xml` dice **cómo se guardan los bloques**.
Los mismos dos archivos los leen el NameNode, los DataNodes y cualquier cliente (incluido Hive).

Crea `config/hadoop/core-site.xml`:

```xml
<?xml version="1.0"?>
<configuration>
  <!-- Sistema de archivos por defecto: HDFS, hablando con el NameNode en el puerto 9000.
       "namenode" es el nombre del contenedor; Docker lo resuelve como si fuera un DNS. -->
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://namenode:9000</value>
  </property>
</configuration>
```

Crea `config/hadoop/hdfs-site.xml`:

```xml
<?xml version="1.0"?>
<configuration>
  <!-- Cuántas copias de cada bloque. Con un solo DataNode solo puede haber una. -->
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>

  <!-- Tamaño de bloque: 1 MB, el mínimo permitido. El valor real de producción es 128 MB.
       Lo bajamos para que un archivo de 5 MB se parta en varios bloques y podamos verlos. -->
  <property>
    <name>dfs.blocksize</name>
    <value>1048576</value>
  </property>

  <!-- Dónde guarda el NameNode sus metadatos y dónde guarda cada DataNode sus bloques.
       Son rutas DENTRO de cada contenedor; en el Paso 4 vas a entrar a verlas. -->
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>/data/dfs/name</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>/data/dfs/data</value>
  </property>

  <!-- Cada cuánto el NameNode revisa si un DataNode dejó de mandar latidos.
       Por defecto tarda 10 minutos en declararlo muerto; con este valor tarda ~50 segundos.
       Solo para el taller: en producción no conviene ser tan impaciente. -->
  <property>
    <name>dfs.namenode.heartbeat.recheck-interval</name>
    <value>10000</value>
  </property>

  <!-- Sin permisos de usuario en HDFS. Simplifica el laboratorio: Hive corre con otro usuario
       que el que sube los archivos. En producción esto va con permisos y Kerberos. -->
  <property>
    <name>dfs.permissions.enabled</name>
    <value>false</value>
  </property>
</configuration>
```

### ✅ Checkpoint

```bash
ls config/hadoop/
```

```
core-site.xml  hdfs-site.xml
```

### ❌ Si falla

| Síntoma | Causa y arreglo |
|---|---|
| Más adelante el NameNode no arranca con `SAXParseException` | XML mal formado: falta cerrar una etiqueta o quedó un carácter extra. Vuelve a copiar el bloque completo. |
| El editor guardó `core-site.xml.txt` | Windows oculta extensiones. Activa *Ver → Extensiones de nombre de archivo* y renómbralo. |

---

## Paso 3: Levanta HDFS con un NameNode y un DataNode

Docker Compose describe en un solo archivo qué contenedores levantar y cómo se conectan. Vas a definir dos
servicios con la **misma imagen** de Hadoop: uno arranca como `namenode` y otro como `datanode`. Ambos reciben
tus dos XML montados sobre la configuración por defecto de la imagen.

Crea `docker-compose.yml` en la raíz del repo:

```yaml
name: hadoop-hive

services:
  namenode:
    image: apache/hadoop:3.4.1
    container_name: namenode
    hostname: namenode
    platform: linux/amd64
    command: ["hdfs", "namenode"]
    environment:
      # La imagen formatea el NameNode la primera vez si esta carpeta no existe.
      ENSURE_NAMENODE_DIR: /data/dfs/name
    ports:
      - "9870:9870"     # interfaz web del NameNode
    volumes:
      - namenode_data:/data
      - ./config/hadoop/core-site.xml:/opt/hadoop/etc/hadoop/core-site.xml
      - ./config/hadoop/hdfs-site.xml:/opt/hadoop/etc/hadoop/hdfs-site.xml
      - ./data:/archivos          # los datasets de tu laptop, visibles dentro del contenedor
      - ./scripts:/scripts

  datanode1:
    image: apache/hadoop:3.4.1
    container_name: datanode1
    hostname: datanode1
    platform: linux/amd64
    command: ["hdfs", "datanode"]
    depends_on:
      - namenode
    ports:
      - "9864:9864"     # interfaz web del DataNode
    volumes:
      - datanode1_data:/data
      - ./config/hadoop/core-site.xml:/opt/hadoop/etc/hadoop/core-site.xml
      - ./config/hadoop/hdfs-site.xml:/opt/hadoop/etc/hadoop/hdfs-site.xml

volumes:
  namenode_data:
  datanode1_data:
```

Dos detalles que importan:

- `volumes` con nombre (`namenode_data`, `datanode1_data`) son discos administrados por Docker. Ahí viven los
  metadatos y los bloques; sobreviven a un `docker compose down` y se borran solo con `down -v`.
- El puerto `9000` (RPC de HDFS) **no** se publica a tu laptop: solo lo usan los contenedores entre sí.

Levanta el clúster:

```bash
docker compose up -d
```

La primera vez tarda entre 20 y 40 segundos: el NameNode se formatea y el DataNode se registra.

### ✅ Checkpoint

```bash
docker compose ps
```

```
NAME        IMAGE                 COMMAND                  SERVICE     STATUS
datanode1   apache/hadoop:3.4.1   "/usr/local/bin/dumb…"   datanode1   Up 30 seconds
namenode    apache/hadoop:3.4.1   "/usr/local/bin/dumb…"   namenode    Up 30 seconds
```

```bash
docker exec namenode hdfs dfsadmin -report | head -12
```

```
Configured Capacity: ...
...
Live datanodes (1):

Name: 172.18.0.3:9866 (datanode1)
Hostname: datanode1
```

Abre <http://localhost:9870>. En *Summary* debe decir **Live Nodes: 1**, y en la pestaña *Datanodes* aparece `datanode1`.

### ❌ Si falla

| Síntoma | Causa y arreglo |
|---|---|
| `port is already allocated` | Otro programa usa el 9870 o el 9864. Cierra el otro programa o cambia el número **izquierdo** del puerto (`"9871:9870"`) y usa ese en el navegador. |
| `docker compose ps` muestra `Restarting` en `namenode` | Mira la causa: `docker compose logs namenode --tail 50`. Si dice `NameNode is not formatted`, ejecuta `docker compose down -v` y `docker compose up -d` otra vez. Si dice `SAXParseException`, corrige el XML (Paso 2). |
| `Live datanodes (0)` | El DataNode todavía se está registrando: espera 20 s y repite. Si sigue en 0, `docker compose logs datanode1 --tail 30`. Un `Incompatible clusterID` significa que el NameNode se re-formateó: `docker compose down -v` y `up -d`. |
| Mac con chip Apple: los contenedores se reinician con `exec format error` o van lentísimos | Rosetta no está activado en Docker Desktop. Ver Paso 0.1, reinicia Docker Desktop y `docker compose up -d` de nuevo. |
| Windows: `error while creating mount source path` | Docker no tiene acceso a la unidad. *Settings → Resources → File sharing*, agrega la carpeta del repo. |
| `localhost:9870` no carga | Espera 30 s más. Si nada, `docker compose logs namenode --tail 20`. |

---

## Paso 4: HDFS frente a tu sistema de archivos local

Este es el paso central de la Parte 1. Vas a subir los datasets a HDFS, comprobar que **los comandos se parecen
a los de Linux pero no operan sobre el mismo disco**, y después ir a buscar los bloques físicos dentro de los
contenedores para ver dónde están de verdad los bytes.

### 4.1 Sube los datos

Los archivos de `data/` están montados en `/archivos` dentro del NameNode. Desde ahí se copian a HDFS
con `hdfs dfs -put`. Sube **solo el archivo de ventas de tu grupo**.

```bash
docker exec namenode hdfs dfs -mkdir -p /datasets/empleados /datasets/word_count /datasets/ventas
docker exec namenode hdfs dfs -put /archivos/empleados/empleados.csv   /datasets/empleados/
docker exec namenode hdfs dfs -put /archivos/word_count/word_count.txt /datasets/word_count/
docker exec namenode hdfs dfs -put /archivos/ventas/ventas_G1.csv      /datasets/ventas/    # <- cambia G1 por tu grupo
```

Por qué carpetas y no archivos sueltos: Hive apunta a **carpetas**, no a archivos. Cada tabla externa va a
leer todo lo que haya en su carpeta.

### ✅ Checkpoint

```bash
docker exec namenode hdfs dfs -ls -R /datasets
```

```
drwxr-xr-x   - hadoop supergroup          0 2026-09-21 16:12 /datasets/empleados
-rw-r--r--   1 hadoop supergroup        401 2026-09-21 16:12 /datasets/empleados/empleados.csv
drwxr-xr-x   - hadoop supergroup          0 2026-09-21 16:12 /datasets/ventas
-rw-r--r--   1 hadoop supergroup    5xxxxxx 2026-09-21 16:12 /datasets/ventas/ventas_G1.csv
drwxr-xr-x   - hadoop supergroup          0 2026-09-21 16:12 /datasets/word_count
-rw-r--r--   1 hadoop supergroup        551 2026-09-21 16:12 /datasets/word_count/word_count.txt
```

Fíjate en la **segunda columna**: ese `1` es el factor de replicación del archivo. En la Parte 2 lo verás cambiar.

### 4.2 Mismos verbos, distinto disco

Compara estos dos comandos, ejecutados en el **mismo contenedor**:

```bash
docker exec namenode hdfs dfs -ls /datasets
docker exec namenode ls /datasets
```

El primero lista la carpeta en HDFS. El segundo responde `ls: cannot access '/datasets': No such file or directory`,
porque en el disco del contenedor esa carpeta **no existe**. `/datasets` es una ruta del sistema de archivos
distribuido, que solo el NameNode conoce.

Prueba los demás verbos (la tabla completa de equivalencias está en [`docs/comandos-hdfs.md`](docs/comandos-hdfs.md)):

```bash
docker exec namenode hdfs dfs -cat /datasets/empleados/empleados.csv
docker exec namenode hdfs dfs -du -h /datasets
docker exec namenode hdfs dfs -get /datasets/empleados/empleados.csv /tmp/copia_local.csv
docker exec namenode ls -l /tmp/copia_local.csv
```

`-get` hace el camino inverso a `-put`: trae el archivo de HDFS al disco local del contenedor.

### 4.3 ¿Dónde están los bytes? Los bloques

HDFS parte cada archivo en **bloques** (aquí de 1 MB) y el NameNode anota en qué DataNode quedó cada uno.
`fsck` (*file system check*) le pregunta al NameNode exactamente eso:

```bash
docker exec namenode hdfs fsck /datasets/ventas/ventas_G1.csv -files -blocks -locations
```

```
/datasets/ventas/ventas_G1.csv 5xxxxxx bytes, replicated: replication=1, 6 block(s):  OK
0. BP-1234567890-172.18.0.2-1758470000000:blk_1073741827_1003 len=1048576 Live_repl=1  [DatanodeInfoWithStorage[172.18.0.3:9866,DS-...,DISK]]
1. BP-1234567890-172.18.0.2-1758470000000:blk_1073741828_1004 len=1048576 Live_repl=1  [DatanodeInfoWithStorage[172.18.0.3:9866,DS-...,DISK]]
...
5. BP-1234567890-172.18.0.2-1758470000000:blk_1073741832_1008 len=xxxxxx  Live_repl=1  [DatanodeInfoWithStorage[172.18.0.3:9866,DS-...,DISK]]

Status: HEALTHY
 Number of data-nodes:  1
 ...
 Total blocks (validated):      6 (avg. block size 8xxxxx B)
 Under-replicated blocks:       0 (0.0 %)
 ...
The filesystem under path '/datasets/ventas/ventas_G1.csv' is HEALTHY
```

Cómo leerlo: el archivo tiene 6 bloques (`blk_1073741827` a `blk_1073741832`), los primeros cinco de exactamente
1 MB y el último con el sobrante. Cada bloque tiene una copia (`Live_repl=1`) en la IP `172.18.0.3`, que es
`datanode1` (lo viste en `dfsadmin -report`).

El script `ubicar_bloques.sh` combina ambos comandos y traduce la IP al nombre del nodo. Es el que vas a usar
en la Parte 2:

```bash
docker exec namenode bash /scripts/ubicar_bloques.sh /datasets/ventas/ventas_G1.csv
```

```
Archivo HDFS: /datasets/ventas/ventas_G1.csv
Bloque                      Tamaño (bytes)   DataNodes con una copia
--------------------------  ---------------  ------------------------
blk_1073741827                      1048576   datanode1
blk_1073741828                      1048576   datanode1
...
```

### 4.4 Entra a los contenedores y toca los bloques

Ahora la prueba definitiva. En el disco del **DataNode** están los bloques como archivos comunes:

```bash
docker exec datanode1 find /data/dfs/data -name 'blk_*' -not -name '*.meta'
```

```
/data/dfs/data/current/BP-1234567890-172.18.0.2-1758470000000/current/finalized/subdir0/subdir0/blk_1073741825
/data/dfs/data/current/BP-1234567890-172.18.0.2-1758470000000/current/finalized/subdir0/subdir0/blk_1073741826
/data/dfs/data/current/BP-1234567890-172.18.0.2-1758470000000/current/finalized/subdir0/subdir0/blk_1073741827
...
```

Un bloque es texto plano. Mira las primeras líneas del **primer bloque de ventas** (toma el número que te dio
`fsck` como bloque `0.`):

```bash
docker exec datanode1 sh -c 'head -3 $(find /data/dfs/data -name blk_1073741827)'
```

```
id_venta,fecha,pais,ciudad,categoria,producto,cantidad,precio_unitario,canal
1,2024-07-14,Guatemala,Quetzaltenango,Hogar,Cafetera,1,689.12,web
2,2024-02-03,Mexico,Guadalajara,Ropa,Zapatos,2,498.30,tienda
```

Y mira el final del mismo bloque:

```bash
docker exec datanode1 sh -c 'tail -c 120 $(find /data/dfs/data -name blk_1073741827)'
```

Casi seguro termina **a media línea**: HDFS corta en el byte 1 048 576 exacto, sin importar dónde termina el
registro. Quien lee (Hive, MapReduce) es el que sabe volver a unir la línea que quedó partida entre dos bloques.

En el disco del **NameNode** no hay ningún bloque, solo el índice:

```bash
docker exec namenode ls /data/dfs/name/current
```

```
VERSION  edits_0000000000000000001-...  edits_inprogress_...  fsimage_0000000000000000000  fsimage_...md5  seen_txid
```

`fsimage` es la foto del sistema de archivos (nombres, carpetas, qué bloques forman cada archivo) y `edits` el
registro de cambios desde esa foto. Si esta carpeta se pierde, los bloques siguen en los DataNodes pero **nadie
sabe a qué archivo pertenecen**. Por eso el NameNode es el punto único de falla que resolvió GFS con su *master*
y que Hadoop mitiga con NameNode HA.

### ✅ Checkpoint

```bash
bash scripts/check.sh hdfs
```

```
✅ Contenedor namenode corriendo
✅ Contenedor datanode1 corriendo
✅ DataNodes vivos según el NameNode: 1
✅ Existe /datasets/empleados en HDFS
✅ Existe /datasets/word_count en HDFS
✅ Existe /datasets/ventas en HDFS
✅ fsck /datasets: HEALTHY

Todo en orden.
```

### ❌ Si falla

| Síntoma | Causa y arreglo |
|---|---|
| `put: '/archivos/ventas/ventas_G1.csv': No such file or directory` | El volumen `./data:/archivos` no está en el compose, o estás fuera de la carpeta del repo. Revisa el Paso 3 y vuelve a `docker compose up -d`. |
| `put: ... File exists` | Ya lo subiste. Para repetir, primero `hdfs dfs -rm /datasets/ventas/ventas_G1.csv`. |
| `mkdir: Call From namenode/... failed on connection exception` | El NameNode todavía está arrancando o está en *safe mode*. Espera 20 s. Si persiste: `docker compose logs namenode --tail 30`. |
| `fsck` dice `Under-replicated blocks` | Con un DataNode y `dfs.replication=1` no debería. Verifica que tu `hdfs-site.xml` diga `1` y que se haya montado: `docker exec namenode cat /opt/hadoop/etc/hadoop/hdfs-site.xml`. |
| El `find` no muestra bloques | Buscaste en el contenedor equivocado (los bloques están en `datanode1`, no en `namenode`). |

### Mini-reto

El archivo de ventas de tu grupo pesa unos 5 MB. ¿Cuántos bloques tendría con el tamaño de bloque por defecto
de Hadoop (128 MB)? ¿Y un archivo de 3.5 MB con el bloque de 1 MB del taller?

<details>
<summary>Respuesta</summary>

Con 128 MB: **1 bloque**. Cualquier archivo menor a 128 MB ocupa un solo bloque, y ese bloque ocupa en disco
solo lo que pesa el archivo (no se reserva el tamaño completo).

Con 1 MB: **4 bloques**: tres de 1 MB y uno de 0.5 MB. El último bloque siempre es el sobrante.
</details>

---

## Paso 5: Un job MapReduce sin escribir código

Antes de Hive, vas a ver cómo se procesaba en Hadoop en 2006: escribiendo un programa MapReduce. No vas a
compilar nada. La imagen de Hadoop trae los ejemplos ya empaquetados; vas a ejecutar el `wordcount` clásico y
**leer** su código fuente en `ejemplos/WordCount.java` mientras corre.

Abre `ejemplos/WordCount.java` en tu editor. Ubica las dos clases: `TokenizerMapper` (fase *map*: emite
`(palabra, 1)` por cada palabra) e `IntSumReducer` (fase *reduce*: suma los unos de cada palabra). Ahora ejecútalo:

```bash
docker exec namenode hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.1.jar \
  wordcount /datasets/word_count /salida/wordcount
```

Tarda unos 10 segundos. En el log verás las dos fases:

```
INFO mapreduce.Job: Running job: job_local...
INFO mapreduce.Job:  map 0% reduce 0%
INFO mapreduce.Job:  map 100% reduce 0%
INFO mapreduce.Job:  map 100% reduce 100%
INFO mapreduce.Job: Job job_local... completed successfully
...
        Map-Reduce Framework
                Map input records=10
                Map output records=75
                ...
                Reduce output records=49
```

Cómo leerlo: el *mapper* leyó 10 líneas y emitió 75 pares `(palabra, 1)`; el *reducer* recibió los pares
agrupados por palabra y produjo 49 palabras distintas con su total. El `job_local` en el nombre te dice que
corrió en **modo local** (un solo proceso): el almacenamiento es distribuido, el cómputo todavía no.
En [`docs/anexo-yarn.md`](docs/anexo-yarn.md) está explicado qué haría falta para distribuirlo.

### ✅ Checkpoint

```bash
docker exec namenode hdfs dfs -cat /salida/wordcount/part-r-00000 | head -6
```

```
a       3
al      1
apuntan 1
archivo 2
archivos        1
bloque  2
```

MapReduce escribe la salida en HDFS, en una carpeta, con un archivo por *reducer* (`part-r-00000`). Guarda mentalmente
la palabra más frecuente: la vas a comparar con Hive en el Paso 8.

### ❌ Si falla

| Síntoma | Causa y arreglo |
|---|---|
| `Output directory hdfs://namenode:9000/salida/wordcount already exists` | MapReduce se niega a sobrescribir. Borra la salida: `docker exec namenode hdfs dfs -rm -r /salida/wordcount` y repite. |
| `Input path does not exist: /datasets/word_count` | No subiste `word_count.txt` en el Paso 4.1. |
| `Error: Could not find or load main class` | El comando se cortó al copiar. Pégalo completo, incluyendo la segunda línea con `wordcount`. |
| Se queda en `map 0% reduce 0%` más de un minuto | Poca memoria en Docker. Revisa que tengas 6 GB asignados (Paso 0.1). |

---

## Paso 6: Agrega Hive

Hive convierte SQL en trabajos sobre los archivos de HDFS. Vas a agregar un tercer contenedor, `hiveserver2`,
que recibe consultas por el puerto 10000. Necesita los **mismos** `core-site.xml` y `hdfs-site.xml` que Hadoop
(para saber dónde está HDFS) más su propio `hive-site.xml`.

Crea `config/hive/hive-site.xml`:

```xml
<?xml version="1.0"?>
<configuration>
  <!-- Dónde guarda Hive los datos de las tablas ADMINISTRADAS. Es una ruta de HDFS. -->
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/user/hive/warehouse</value>
  </property>

  <!-- Carpeta temporal de Hive en HDFS para resultados intermedios. -->
  <property>
    <name>hive.exec.scratchdir</name>
    <value>/tmp/hive</value>
  </property>

  <!-- Motor de ejecución: Tez en modo local (un solo proceso, sin YARN).
       Estas propiedades son las que trae la imagen por defecto; hay que repetirlas
       porque este archivo reemplaza al suyo. -->
  <property>
    <name>hive.execution.engine</name>
    <value>tez</value>
  </property>
  <property>
    <name>tez.local.mode</name>
    <value>true</value>
  </property>
  <property>
    <name>tez.runtime.optimize.local.fetch</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.exec.submit.local.task.via.child</name>
    <value>false</value>
  </property>
  <property>
    <name>mapreduce.framework.name</name>
    <value>local</value>
  </property>
  <property>
    <name>hive.tez.exec.inplace.progress</name>
    <value>false</value>
  </property>

  <!-- Hive habla con HDFS como usuario "hive", no como el usuario que envía la consulta. -->
  <property>
    <name>hive.server2.enable.doAs</name>
    <value>false</value>
  </property>
  <property>
    <name>metastore.metastore.event.db.notification.api.auth</name>
    <value>false</value>
  </property>

  <!-- Hive 4 convierte por defecto las tablas administradas no transaccionales en externas
       "con purga". Lo desactivamos para que el experimento del Paso 9 muestre una tabla
       administrada de verdad. -->
  <property>
    <name>metastore.metadata.transformer.class</name>
    <value></value>
  </property>
</configuration>
```

Crea en HDFS las dos carpetas que Hive espera:

```bash
docker exec namenode hdfs dfs -mkdir -p /user/hive/warehouse /tmp/hive
```

Agrega el servicio al `docker-compose.yml`, **debajo de `datanode1` y con la misma indentación** (dos espacios,
al nivel de `namenode:` y `datanode1:`):

```yaml
  hiveserver2:
    image: apache/hive:4.0.0
    container_name: hiveserver2
    hostname: hiveserver2
    platform: linux/amd64
    depends_on:
      - namenode
    environment:
      SERVICE_NAME: hiveserver2          # la imagen puede arrancar como metastore o como hiveserver2
      HIVE_CUSTOM_CONF_DIR: /hive_custom_conf
    ports:
      - "10000:10000"   # puerto JDBC/Thrift (beeline se conecta aquí)
      - "10002:10002"   # interfaz web de HiveServer2
    volumes:
      - ./config/hadoop/core-site.xml:/hive_custom_conf/core-site.xml
      - ./config/hadoop/hdfs-site.xml:/hive_custom_conf/hdfs-site.xml
      - ./config/hive/hive-site.xml:/hive_custom_conf/hive-site.xml
```

Levanta solo el nuevo servicio (los otros dos siguen corriendo):

```bash
docker compose up -d hiveserver2
```

Hive tarda **1 a 2 minutos** en estar listo: la primera vez inicializa su *metastore* (una base de datos
Derby embebida donde guarda la definición de las tablas). Mientras, mira el progreso:

```bash
docker compose logs -f hiveserver2
```

Sal con `Ctrl+C` cuando veas líneas que mencionen `HiveServer2` arrancado o dejen de aparecer mensajes nuevos.

### ✅ Checkpoint

Conéctate con **beeline**, el cliente de línea de comandos de Hive:

```bash
docker exec -it hiveserver2 beeline -u jdbc:hive2://localhost:10000
```

```
Connecting to jdbc:hive2://localhost:10000
Connected to: Apache Hive (version 4.0.0)
Driver: Hive JDBC (version 4.0.0)
Transaction isolation: TRANSACTION_REPEATABLE_READ
Beeline version 4.0.0 by Apache Hive
0: jdbc:hive2://localhost:10000>
```

En ese prompt escribe (con el punto y coma):

```sql
SHOW DATABASES;
```

```
+----------------+
| database_name  |
+----------------+
| default        |
+----------------+
```

Para salir de beeline: `!quit`. Abre también <http://localhost:10002>: es la consola web de HiveServer2, donde
aparecerán las consultas que ejecutes.

### ❌ Si falla

| Síntoma | Causa y arreglo |
|---|---|
| `Could not open client transport ... Connection refused` | Hive todavía está arrancando. Espera 30 s y reintenta. Si pasan 3 minutos, `docker compose logs hiveserver2 --tail 50`. |
| El log dice `Schema initialization failed` o `metastore_db already exists` | Reiniciaste el contenedor y la inicialización chocó con la anterior. Agrega `IS_RESUME: "true"` al bloque `environment:` de `hiveserver2` y vuelve a `docker compose up -d hiveserver2`. |
| `Connection refused` a `namenode:9000` en el log | Hive no ve HDFS: falta el volumen de `core-site.xml` en `/hive_custom_conf`, o `namenode` no está arriba (`docker compose ps`). |
| El contenedor sale con `Exited (1)` de inmediato | Casi siempre un error de indentación en el YAML. `docker compose config` te dice la línea. |
| En Windows/Git Bash: `the input device is not a TTY` | Antepón `winpty`: `winpty docker exec -it hiveserver2 beeline ...`. En PowerShell no hace falta. |
| `Permission denied` al crear `/tmp/hive` o el warehouse | `dfs.permissions.enabled` no quedó en `false` en `hdfs-site.xml`. Corrígelo y `docker compose restart namenode hiveserver2`. |

---

## Paso 7: Tablas externas: SQL sobre los archivos que ya están en HDFS

Aquí está la idea de *schema-on-read* que vimos en la clase de Ecosistema: los datos ya están en HDFS desde el
Paso 4, sin esquema. Una **tabla externa** solo le dice a Hive "esta carpeta contiene filas con estas columnas y
este separador". No copia ni mueve nada: agrega **metadatos** encima de archivos que ya existen.

Entra a beeline y crea las tres tablas. No cambies nada: las rutas son las carpetas del Paso 4.

```bash
docker exec -it hiveserver2 beeline -u jdbc:hive2://localhost:10000
```

```sql
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
```

Tres cosas para notar:

- `EXTERNAL` es la palabra clave. Sin ella, Hive crearía una tabla *administrada* (Paso 9).
- `LOCATION` apunta a una **carpeta**. Todo archivo que caiga ahí pasa a ser parte de la tabla, sin `INSERT`.
- `skip.header.line.count` hace que Hive ignore la primera línea de cada CSV, que es el encabezado.
  `word_count` no la necesita y tampoco lleva separador: cada línea completa es una fila con una sola columna.

### ✅ Checkpoint

Siempre dentro de beeline:

```sql
SHOW TABLES;
```

```
+-------------+
|  tab_name   |
+-------------+
| empleados   |
| ventas      |
| word_count  |
+-------------+
```

```sql
SELECT * FROM empleados LIMIT 3;
```

```
+---------------+-------------------+-------------------------+--------------------+-----------------+
| empleados.id  |  empleados.nombre | empleados.departamento  | empleados.salario  | empleados.pais  |
+---------------+-------------------+-------------------------+--------------------+-----------------+
| 1             | Ana Morales       | Ingenieria              | 7500               | Guatemala       |
| 2             | Luis Castillo     | Recursos Humanos        | 5000               | Guatemala       |
| 3             | Carla Mendez      | Ingenieria              | 6000               | El Salvador     |
+---------------+-------------------+-------------------------+--------------------+-----------------+
```

```sql
DESCRIBE FORMATTED empleados;
```

Busca estas dos líneas en la salida (es larga):

```
| Location:                     | hdfs://namenode:9000/datasets/empleados          |
| Table Type:                   | EXTERNAL_TABLE                                   |
```

Eso es todo lo que Hive guardó: dónde están los archivos y cómo interpretarlos.

### ❌ Si falla

| Síntoma | Causa y arreglo |
|---|---|
| La primera fila del `SELECT` es `id, nombre, departamento...` | Falta `TBLPROPERTIES ('skip.header.line.count'='1')`. `DROP TABLE empleados;` y créala de nuevo. |
| Todas las columnas salen `NULL` | El separador no coincide (`FIELDS TERMINATED BY ','`) o el archivo no es el esperado. Revisa con `hdfs dfs -cat`. |
| `SELECT COUNT(*) FROM ventas` da 0 | La carpeta `/datasets/ventas/` está vacía: no subiste el CSV de tu grupo (Paso 4.1). |
| `SELECT COUNT(*) FROM ventas` da 150000 o más | Subiste más de un archivo a `/datasets/ventas/`; la tabla lee la carpeta completa. Borra el que sobra con `hdfs dfs -rm`. |
| `Table already exists` | Ya la creaste. Sigue adelante o `DROP TABLE` y repite. |
| `Error: ... Permission denied` | `dfs.permissions.enabled` no está en `false`. Ver Paso 6. |

---

## Paso 8: Consultas

Con las tablas definidas, Hive se usa como cualquier base SQL. Cada consulta se traduce a un plan que lee los
archivos bloque por bloque. La primera consulta de la sesión tarda 20 o 30 segundos más porque Tez arranca;
las siguientes son rápidas.

Dentro de beeline:

**Filtro:**

```sql
SELECT nombre, departamento, salario
FROM empleados
WHERE departamento = 'Ingenieria' AND salario > 6000;
```

```
+--------------+---------------+----------+
|    nombre    | departamento  | salario  |
+--------------+---------------+----------+
| Ana Morales  | Ingenieria    | 7500     |
| Elena Ruiz   | Ingenieria    | 8200     |
+--------------+---------------+----------+
```

**Agregación:**

```sql
SELECT departamento, COUNT(*) AS personas, ROUND(AVG(salario), 2) AS salario_promedio
FROM empleados
GROUP BY departamento
ORDER BY salario_promedio DESC;
```

```
+-------------------+-----------+-------------------+
|   departamento    | personas  | salario_promedio  |
+-------------------+-----------+-------------------+
| Finanzas          | 2         | 6950.0            |
| Ingenieria        | 4         | 6900.0            |
| Recursos Humanos  | 1         | 5000.0            |
| Ventas            | 3         | 4833.33           |
+-------------------+-----------+-------------------+
```

**Sobre el archivo grande** (aquí Hive lee los 6 bloques):

```sql
SELECT COUNT(*) FROM ventas;
```

```
+--------+
|  _c0   |
+--------+
| 75000  |
+--------+
```

```sql
SELECT pais, ROUND(SUM(cantidad * precio_unitario), 2) AS total_ventas, COUNT(*) AS num_ventas
FROM ventas
GROUP BY pais
ORDER BY total_ventas DESC;
```

El resultado depende de tu grupo (cada archivo tiene datos distintos). Guarda esta consulta: el mini-reto de tu
bitácora es una variante.

**Word count, ahora en SQL.** `split` parte cada línea en palabras y `explode` convierte esa lista en una fila
por palabra; `LATERAL VIEW` es la forma de Hive de "cruzar" cada línea con sus palabras:

```sql
SELECT palabra, COUNT(*) AS total
FROM word_count LATERAL VIEW explode(split(linea, ' ')) t AS palabra
GROUP BY palabra
ORDER BY total DESC, palabra
LIMIT 5;
```

```
+-----------+--------+
|  palabra  | total  |
+-----------+--------+
| guarda    | 6      |
| el        | 5      |
| bloques   | 4      |
| cada      | 4      |
| datanode  | 4      |
+-----------+--------+
```

Compara con `part-r-00000` del Paso 5: mismos números. Una línea de SQL contra 60 líneas de Java.

**¿Y qué hace Hive por debajo?** Pídele el plan:

```sql
EXPLAIN SELECT pais, SUM(cantidad * precio_unitario) FROM ventas GROUP BY pais;
```

En la salida busca esto:

```
| Vertex dependency in root stage                    |
| Reducer 2 <- Map 1 (SIMPLE_EDGE)                   |
```

Hive generó una fase **Map** (leer los bloques, calcular `cantidad * precio_unitario`, agrupar parcialmente por
país) y una fase **Reduce** (sumar los parciales de cada país). Es exactamente la estructura de `WordCount.java`.
Hive no reemplazó a MapReduce; lo escondió detrás de SQL. Esa fue la razón por la que Facebook lo creó en 2008.

### ✅ Checkpoint

```bash
bash scripts/check.sh hive
```

```
✅ Contenedor hiveserver2 corriendo
✅ Tabla empleados existe en Hive
✅ Tabla word_count existe en Hive
✅ Tabla ventas existe en Hive

Todo en orden.
```

### ❌ Si falla

| Síntoma | Causa y arreglo |
|---|---|
| La consulta se queda en `Map 1: 0/1` mucho tiempo | Primera consulta de la sesión: Tez arranca. Espera hasta 1 minuto. |
| `Vertex failed` / `OutOfMemoryError` | Poca RAM en Docker. Sube a 8 GB en *Settings → Resources*. |
| `Invalid table alias or column reference` | Error de tipeo en un nombre de columna. Revisa con `DESCRIBE ventas;`. |
| El word count muestra una palabra vacía `""` | Hay dobles espacios en el texto. Agrega `WHERE palabra <> ''` antes del `GROUP BY`. |

### Mini-reto

¿Cuál es la ciudad con más ventas (en dinero) en el archivo de tu grupo? Escribe la consulta.

<details>
<summary>Respuesta</summary>

```sql
SELECT ciudad, ROUND(SUM(cantidad * precio_unitario), 2) AS total
FROM ventas
GROUP BY ciudad
ORDER BY total DESC
LIMIT 1;
```

La ciudad concreta cambia según el grupo.
</details>

---

## Paso 9: Experimento: `DROP` de una tabla externa frente a una administrada

Vas a crear una tabla **administrada** (sin `EXTERNAL`), ver dónde la guarda Hive, y luego borrar ambas. La
diferencia en lo que pasa con los archivos es la razón por la que en un Data Lake casi todo es externo.

Dentro de beeline, crea una copia administrada de `empleados`:

```sql
CREATE TABLE empleados_admin AS SELECT * FROM empleados;
DESCRIBE FORMATTED empleados_admin;
```

```
| Location:                     | hdfs://namenode:9000/user/hive/warehouse/empleados_admin |
| Table Type:                   | MANAGED_TABLE                                            |
```

Hive escribió los datos en **su** carpeta, el *warehouse*. Míralo desde HDFS, en **otra terminal**:

```bash
docker exec namenode hdfs dfs -ls -R /user/hive/warehouse
```

```
drwxr-xr-x   - hive supergroup          0 2026-09-21 16:40 /user/hive/warehouse/empleados_admin
-rw-r--r--   1 hive supergroup        3xx 2026-09-21 16:40 /user/hive/warehouse/empleados_admin/000000_0
```

Fíjate en el dueño: `hive`, no `hadoop`. Hive escribió ese archivo, así que Hive lo considera suyo.

Ahora borra las dos tablas en beeline:

```sql
DROP TABLE empleados_admin;
DROP TABLE empleados;
SHOW TABLES;
```

Las dos desaparecen del catálogo. Ahora revisa HDFS:

```bash
docker exec namenode hdfs dfs -ls /user/hive/warehouse
docker exec namenode hdfs dfs -ls /datasets/empleados
```

```
(vacío: /user/hive/warehouse/empleados_admin ya no existe)

Found 1 items
-rw-r--r--   1 hadoop supergroup        401 2026-09-21 16:12 /datasets/empleados/empleados.csv
```

- La tabla **administrada** se llevó sus datos: `DROP` borró la carpeta del warehouse.
- La tabla **externa** solo borró los metadatos: `empleados.csv` sigue intacto en `/datasets/empleados/`.

Por eso en un Data Lake, donde varios equipos y varias herramientas (Hive, Spark, Trino, Athena) leen los mismos
archivos, las tablas son externas: ningún `DROP` de un equipo puede borrar los datos de otro.

Vuelve a crear `empleados` (la necesitas para la defensa oral). Es el mismo `CREATE EXTERNAL TABLE` del Paso 7;
al ejecutarlo, los datos "reaparecen" en la tabla porque nunca se fueron de HDFS:

```sql
CREATE EXTERNAL TABLE empleados (
  id INT, nombre STRING, departamento STRING, salario INT, pais STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/datasets/empleados/'
TBLPROPERTIES ('skip.header.line.count'='1');

SELECT COUNT(*) FROM empleados;
```

```
+------+
| _c0  |
+------+
| 10   |
+------+
```

### ✅ Checkpoint

Toma la captura **E5** de la bitácora: el `ls` del warehouse antes y después del `DROP`, y el `ls` de
`/datasets/empleados` después.

### ❌ Si falla

| Síntoma | Causa y arreglo |
|---|---|
| `DESCRIBE FORMATTED empleados_admin` dice `EXTERNAL_TABLE` con `TRANSLATED_TO_EXTERNAL` | Falta la propiedad `metastore.metadata.transformer.class` vacía en `hive-site.xml` (Paso 6). Agrégala y `docker compose restart hiveserver2`. El experimento sigue funcionando (Hive marca esas tablas con `external.table.purge=true`, así que el `DROP` borra igual), pero la etiqueta confunde. |
| `CREATE TABLE ... AS SELECT` falla con `Permission denied` | Hive no puede escribir en `/user/hive/warehouse`. Ver Paso 6 (`dfs.permissions.enabled=false`). |
| Después de `DROP TABLE empleados`, `/datasets/empleados` quedó vacío | La tabla no era externa: se creó sin `EXTERNAL`. Vuelve a subir el CSV (Paso 4.1) y créala con `EXTERNAL`. |

---

# Parte 2: Tres nodos, réplicas y un nodo caído

## Paso 10: Tres DataNodes y factor de replicación 2

Hasta ahora cada bloque existe una sola vez: si `datanode1` muere, se pierde todo. Vas a agregar dos DataNodes
y pedirle a HDFS **dos copias** de cada bloque. Elegimos 2 y no el 3 por defecto de Hadoop por dos razones:
con 3 nodos y 3 copias, todos los nodos tendrían todo (no se vería la distribución), y con 2 copias, cuando
un nodo caiga en el Paso 11, HDFS **sí** va a poder reconstruir la copia perdida en el nodo que queda libre.

### 10.1 Cambia la replicación

En `config/hadoop/hdfs-site.xml`, cambia el valor de `dfs.replication` de `1` a `2`:

```xml
  <property>
    <name>dfs.replication</name>
    <value>2</value>
  </property>
```

### 10.2 Agrega dos DataNodes

En `docker-compose.yml`, agrega estos dos servicios debajo de `datanode1` (misma indentación) y los dos volúmenes
nuevos al final:

```yaml
  datanode2:
    image: apache/hadoop:3.4.1
    container_name: datanode2
    hostname: datanode2
    platform: linux/amd64
    command: ["hdfs", "datanode"]
    depends_on:
      - namenode
    ports:
      - "9865:9864"
    volumes:
      - datanode2_data:/data
      - ./config/hadoop/core-site.xml:/opt/hadoop/etc/hadoop/core-site.xml
      - ./config/hadoop/hdfs-site.xml:/opt/hadoop/etc/hadoop/hdfs-site.xml

  datanode3:
    image: apache/hadoop:3.4.1
    container_name: datanode3
    hostname: datanode3
    platform: linux/amd64
    command: ["hdfs", "datanode"]
    depends_on:
      - namenode
    ports:
      - "9866:9864"
    volumes:
      - datanode3_data:/data
      - ./config/hadoop/core-site.xml:/opt/hadoop/etc/hadoop/core-site.xml
      - ./config/hadoop/hdfs-site.xml:/opt/hadoop/etc/hadoop/hdfs-site.xml
```

```yaml
volumes:
  namenode_data:
  datanode1_data:
  datanode2_data:
  datanode3_data:
```

Levanta los nuevos. `namenode` y `datanode1` siguen corriendo con su configuración: el factor de replicación lo
decide **el cliente** que escribe (el comando `hdfs dfs` lee el XML cada vez que lo ejecutas), no el NameNode.

```bash
docker compose up -d
```

Espera 30 segundos y confirma que el NameNode ya los ve:

```bash
docker exec namenode hdfs dfsadmin -report | grep -E "Live datanodes|Hostname"
```

```
Live datanodes (3):
Hostname: datanode1
Hostname: datanode2
Hostname: datanode3
```

### 10.3 Pide la segunda copia

Los archivos que ya subiste se crearon con replicación 1, y HDFS no los cambia solo. `-setrep` le pide al
NameNode el nuevo factor y `-w` espera hasta que las copias existan:

```bash
docker exec namenode hdfs dfs -setrep -w 2 /datasets
```

```
Replication 2 set: /datasets/empleados/empleados.csv
Replication 2 set: /datasets/ventas/ventas_G1.csv
Replication 2 set: /datasets/word_count/word_count.txt
Waiting for /datasets/empleados/empleados.csv .... done
Waiting for /datasets/ventas/ventas_G1.csv ... done
Waiting for /datasets/word_count/word_count.txt ... done
```

Lo que pasó: el NameNode le ordenó a `datanode1` copiar cada bloque a otro nodo, y eligió el destino bloque por
bloque. Los archivos que subas de aquí en adelante nacen ya con dos copias.

### ✅ Checkpoint

```bash
docker exec namenode bash /scripts/ubicar_bloques.sh /datasets/ventas/ventas_G1.csv
```

```
Archivo HDFS: /datasets/ventas/ventas_G1.csv
Bloque                      Tamaño (bytes)   DataNodes con una copia
--------------------------  ---------------  ------------------------
blk_1073741827                      1048576   datanode1 datanode3
blk_1073741828                      1048576   datanode1 datanode2
blk_1073741829                      1048576   datanode1 datanode2
blk_1073741830                      1048576   datanode1 datanode3
blk_1073741831                      1048576   datanode1 datanode2
blk_1073741832                       2xxxxx   datanode1 datanode3
```

Cada bloque está en `datanode1` (la copia original) y en **uno** de los dos nuevos. Ningún nodo tiene el archivo
completo salvo `datanode1`; el archivo solo existe entero como *concepto* en el NameNode. Esto es el
almacenamiento distribuido.

Compruébalo físicamente: busca un bloque que según la tabla esté en `datanode2` y otro en `datanode3`:

```bash
docker exec datanode2 find /data/dfs/data -name 'blk_*' -not -name '*.meta' | xargs -n1 basename
docker exec datanode3 find /data/dfs/data -name 'blk_*' -not -name '*.meta' | xargs -n1 basename
```

Cada nodo tiene solo los bloques que le tocaron. Abre <http://localhost:9870>: *Live Nodes: 3*, y en
*Datanodes* se ve cuántos bloques tiene cada uno. Los links de esa tabla apuntan a `datanode2:9864`, un nombre que
tu laptop no conoce; para ver la UI de cada DataNode usa <http://localhost:9864>, <http://localhost:9865> y
<http://localhost:9866>.

```bash
bash scripts/check.sh cluster
```

```
✅ Contenedor namenode corriendo
✅ Contenedor datanode1 corriendo
✅ Contenedor datanode2 corriendo
✅ Contenedor datanode3 corriendo
✅ DataNodes vivos según el NameNode: 3
✅ Replicación promedio en /datasets/ventas: 2.0

Todo en orden.
```

Toma las capturas **E1** y **E2** de la bitácora.

### ❌ Si falla

| Síntoma | Causa y arreglo |
|---|---|
| `Live datanodes (1)` después de un minuto | Los nuevos no arrancaron: `docker compose ps` y `docker compose logs datanode2 --tail 30`. Si dice `Incompatible clusterID`, ese volumen es de un clúster viejo: `docker compose down -v` borra todo y hay que repetir desde el Paso 3 (el Paso 4 toma un minuto). |
| `setrep` se queda en `Waiting for ...` sin terminar | Solo hay un DataNode vivo, no hay dónde poner la segunda copia. Revisa el punto anterior. |
| `ubicar_bloques.sh` muestra IPs en vez de nombres | `dfsadmin -report` no devolvió hostnames. Usa la IP y compárala con `docker exec namenode hdfs dfsadmin -report`. |
| Todos los bloques muestran solo `datanode1` | Falta el `-setrep` (10.3), o lo corriste antes de que los nodos se registraran. Repítelo. |
| `port is already allocated` en 9865/9866 | Cambia el número izquierdo del puerto en el compose. |

### Mini-reto

Sube el factor de replicación de `/datasets/word_count` a 3 y vuelve a ubicar sus bloques. ¿Qué cambia? ¿Qué pasaría
si pidieras 4?

<details>
<summary>Respuesta</summary>

```bash
docker exec namenode hdfs dfs -setrep -w 3 /datasets/word_count
docker exec namenode bash /scripts/ubicar_bloques.sh /datasets/word_count/word_count.txt
```

El único bloque del archivo aparece en los tres nodos. Con 4, el `-setrep` se aceptaría (el NameNode anota que
quiere 4) pero `-w` esperaría para siempre: no hay un cuarto DataNode. `fsck` lo reportaría como
*under-replicated*. HDFS nunca pone dos copias del mismo bloque en el mismo nodo.
</details>

---

## Paso 11: Apaga un DataNode

Ahora rompes algo a propósito. Vas a apagar `datanode2` y observar tres cosas en orden: los datos siguen
disponibles, el NameNode detecta la caída, y HDFS reconstruye por sí solo las copias que se perdieron.
Es la **P** de CAP en vivo: el sistema sigue respondiendo con una partición, porque replicó por adelantado.

### 11.1 Apaga el nodo

```bash
docker compose stop datanode2
```

### 11.2 Los datos siguen ahí

Inmediatamente, lee el archivo de ventas. Algunos de sus bloques tenían una copia en `datanode2`:

```bash
docker exec namenode hdfs dfs -cat /datasets/ventas/ventas_G1.csv | wc -l
```

```
75001
```

Las 75 000 filas más el encabezado. El cliente pidió el archivo, el NameNode le dio la lista de bloques con sus
ubicaciones, y para cada bloque el cliente usó la copia que sí respondió. Nadie notó la caída.

### 11.3 El NameNode se da cuenta

`datanode2` dejó de mandar latidos. Con la configuración del taller, el NameNode lo declara muerto en unos
**50 segundos**. Espera un minuto y consulta:

```bash
docker exec namenode hdfs dfsadmin -report | grep -E "Live datanodes|Dead datanodes"
```

```
Live datanodes (2):
Dead datanodes (1):
```

En <http://localhost:9870>: *Live Nodes: 2, Dead Nodes: 1*. Toma la captura **E6**.

### 11.4 HDFS se repara solo

Cada bloque que tenía una copia en `datanode2` ahora tiene una sola copia viva, menos de las 2 pedidas. En cuanto
declara muerto el nodo, el NameNode ordena copiar esos bloques al nodo que no los tiene. Míralo:

```bash
docker exec namenode bash /scripts/ubicar_bloques.sh /datasets/ventas/ventas_G1.csv
```

```
blk_1073741827                      1048576   datanode1 datanode3
blk_1073741828                      1048576   datanode1 datanode3     <- antes estaba en datanode2
blk_1073741829                      1048576   datanode1 datanode3     <- antes estaba en datanode2
...
```

Y `fsck` vuelve a estar sano:

```bash
docker exec namenode hdfs fsck /datasets | grep -E "Under-replicated|Missing|HEALTHY"
```

```
 Under-replicated blocks:       0 (0.0 %)
 Missing blocks:                0
 Missing replicas:              0 (0.0 %)
The filesystem under path '/datasets' is HEALTHY
```

Si lo corres demasiado pronto verás `Under-replicated blocks: 3` (o el número que te toque): la reparación está en
curso. Espera 20 segundos y repite.

### 11.5 El nodo regresa

```bash
docker compose start datanode2
```

Espera 30 segundos y vuelve a ubicar los bloques. Los que se copiaron a `datanode3` ahora tienen **tres** copias
(una de más). El NameNode las detecta como *over-replicated* y ordena borrar una de las tres (él decide cuál).
En un minuto todo queda otra vez con exactamente dos copias.

### ✅ Checkpoint

```bash
docker exec namenode hdfs dfsadmin -report | grep -E "Live datanodes|Dead datanodes"
docker exec namenode hdfs fsck /datasets | grep -E "Over-replicated|Under-replicated|HEALTHY"
```

```
Live datanodes (3):
Dead datanodes (0):
 Over-replicated blocks:        0 (0.0 %)
 Under-replicated blocks:       0 (0.0 %)
The filesystem under path '/datasets' is HEALTHY
```

### ❌ Si falla

| Síntoma | Causa y arreglo |
|---|---|
| Después de 2 minutos sigue `Live datanodes (3)` con `datanode2` apagado | El `dfs.namenode.heartbeat.recheck-interval` no se aplicó (el NameNode arrancó con la config vieja). Confirma con `docker exec namenode hdfs getconf -confKey dfs.namenode.heartbeat.recheck-interval`; si no dice `10000`, `docker compose restart namenode` y espera a que los DataNodes se re-registren. |
| `Under-replicated` no baja a 0 | Solo hay un nodo vivo además de `datanode1`, y ya tiene ese bloque: no hay dónde poner la segunda copia. Revisa que `datanode3` esté vivo. |
| Al leer el archivo con el nodo caído: `Could not obtain block` | El cliente intentó el nodo muerto y no reintentó. Repite el `-cat`; a la segunda usa la otra copia. |
| `datanode2` no vuelve a `Live` | `docker compose logs datanode2 --tail 20`. Un `start` conserva el volumen, así que no debería haber `clusterID` distinto. |

### Mini-reto

Con replicación 2 y 3 nodos, ¿qué pasa si apagas **dos** DataNodes a la vez? ¿Puedes seguir leyendo el archivo
completo? Piensa antes de probar (y si pruebas, recuerda volver a levantarlos).

<details>
<summary>Respuesta</summary>

Depende de qué dos. Cada bloque está en `datanode1` y en uno de los otros dos. Si apagas `datanode2` y `datanode3`,
todo sigue en `datanode1`: se lee completo. Si apagas `datanode1` y cualquier otro, los bloques cuya segunda copia
estaba en el nodo apagado quedan **sin copias vivas**: el archivo no se puede leer entero, y `fsck` reporta
*Missing blocks*. HDFS no puede reconstruir lo que no tiene en ninguna parte. Por eso el factor por defecto es 3
y por eso se reparten copias entre *racks* distintos.
</details>

---

## Paso 12: Limpieza

Cuando termines (y hayas tomado todas las capturas), apaga y borra todo lo del taller, incluidos los volúmenes:

```bash
docker compose down -v
```

`down -v` solo toca los contenedores, la red y los volúmenes **de este compose**. No afecta a otros proyectos
Docker que tengas. Nunca uses `docker stop $(docker ps -q)` o `docker rm` masivos: borran contenedores ajenos.

Para volver a levantar todo otro día (por ejemplo, antes de la defensa oral): `docker compose up -d`, esperar
un minuto, repetir el Paso 4.1 (subir datos), el Paso 6 (`mkdir` del warehouse) y el Paso 7 (crear tablas).
Como tu `hdfs-site.xml` ya dice `dfs.replication=2`, los archivos nacen con dos copias y el Paso 10.3 no hace falta.
Con las tres carpetas y el `docker-compose.yml` ya escritos, toma cinco minutos.

### ✅ Checkpoint

```bash
docker compose ps
```

No debe listar ningún contenedor.

---

## Errores comunes en cualquier paso

| Síntoma | Qué hacer |
|---|---|
| Un comando `docker exec` dice `No such container` | El contenedor no está arriba. `docker compose ps` para ver el estado y `docker compose up -d` para levantarlo. |
| `docker compose` dice `no configuration file provided` | No estás en la carpeta del repo. |
| Un servicio se queda en `Restarting` | `docker compose logs <servicio> --tail 50` y busca la primera línea con `ERROR` o `Exception`. |
| Cambié un XML y no hace efecto | Los procesos leen la configuración al arrancar: `docker compose restart <servicio>`. |
| Todo se puso lento | Docker Desktop tiene poca RAM. Cierra otros programas o sube la memoria en *Settings → Resources*. |
| Quiero empezar de cero | `docker compose down -v` y desde el Paso 3. Tus XML y el compose se conservan. |
| Windows: `docker exec -it` falla con `not a TTY` | Usa `winpty docker exec -it ...` en Git Bash, o PowerShell. |

## Glosario

| Término | Qué es |
|---|---|
| **HDFS** | *Hadoop Distributed File System.* Sistema de archivos que reparte archivos grandes en bloques entre muchas máquinas. Implementación abierta de GFS (Google, 2003). |
| **NameNode** | Proceso que guarda el índice de HDFS: nombres, carpetas, bloques de cada archivo y en qué DataNode está cada copia. Uno por clúster. |
| **DataNode** | Proceso que guarda bloques en su disco y los sirve a quien los pida. Uno por máquina. |
| **Bloque** | Unidad en que HDFS parte un archivo. 128 MB por defecto; 1 MB en este taller. |
| **Réplica / factor de replicación** | Cuántas copias de cada bloque mantiene HDFS en nodos distintos. 3 por defecto. |
| **Latido (heartbeat)** | Mensaje que cada DataNode manda al NameNode cada 3 segundos para decir "sigo vivo". |
| **fsck** | Comando que pregunta al NameNode por el estado de los archivos y la ubicación de sus bloques. |
| **MapReduce** | Modelo de programación de Google (2004): una fase *map* que transforma registros en pares clave-valor y una fase *reduce* que agrupa por clave. |
| **YARN** | Administrador de recursos de Hadoop que reparte tareas entre nodos. No se usa en este taller (ver anexo). |
| **Hive** | Capa SQL sobre Hadoop. Traduce consultas a planes de ejecución sobre archivos de HDFS. Creada en Facebook en 2008. |
| **HiveServer2** | Servicio de Hive que recibe consultas por JDBC (puerto 10000). |
| **Metastore** | Base de datos donde Hive guarda la definición de tablas, columnas y ubicaciones. Aquí, Derby embebido. |
| **beeline** | Cliente de terminal de Hive. |
| **Tabla externa** | Tabla cuyos datos administra el usuario: Hive solo guarda metadatos. `DROP` no borra los archivos. |
| **Tabla administrada** | Tabla cuyos datos administra Hive, en el warehouse. `DROP` borra los archivos. |
| **Schema-on-read** | Aplicar el esquema al leer, no al escribir. Los archivos se guardan tal cual y la tabla se define después. |
| **Tez** | Motor de ejecución de Hive que reemplazó a MapReduce clásico. Aquí corre en modo local. |

## Para seguir

- [`docs/anexo-yarn.md`](docs/anexo-yarn.md): cómo se distribuye también el cómputo.
- [`docs/comandos-hdfs.md`](docs/comandos-hdfs.md): referencia completa de comandos.
- Siguiente taller del curso: **Kafka**, donde la distribución no es por bloques sino por *particiones* y
  la coordinación no la hace un NameNode sino los propios brokers.

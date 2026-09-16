# Entregable y evaluación del taller

El taller se califica sobre **100 %** en dos partes. El peso final dentro del rubro "Tareas y prácticas"
se comunica al cierre del semestre.

| Parte | Peso | Quién | Qué es |
|---|---|---|---|
| Bitácora | 40 % | **Individual** | Documento corto con tus evidencias y tus respuestas |
| Defensa oral | 60 % | **Por grupo, con una parte distinta para cada integrante** | Demostración en vivo y preguntas del catedrático |

El taller se hace en grupo (cada grupo tiene su archivo `ventas_G#.csv` y su mini-reto), pero **cada estudiante
levanta el entorno en su propia laptop, toma sus propias capturas y escribe sus propias respuestas**. Dos bitácoras
del mismo grupo pueden tener las mismas consultas y resultados parecidos, pero no las mismas capturas ni las mismas
palabras.

## 1. Bitácora (40 %, individual)

Un archivo `bitacora.md` por estudiante, llenado a partir de [`plantilla-bitacora.md`](plantilla-bitacora.md),
entregado por git (ver más abajo, "Cómo se entrega").
**Fecha de entrega:** la fecha de la defensa oral se anuncia en clase; el Pull Request se abre **antes de que empiece
esa clase**. Entregas tardías se evalúan solo con la defensa oral.
No es un informe: es evidencia de que lo corriste y de que entendiste lo que viste.

### 1.1 Evidencias (capturas de pantalla, tomadas en tu laptop)

Cada captura debe verse completa y legible. Si es de terminal, que se vea el comando y la salida. Las capturas
se toman en tu máquina: los nombres de contenedor, fechas e IPs de tu captura deben coincidir entre sí.

| # | Evidencia | Paso |
|---|---|---|
| E1 | Interfaz del NameNode (`localhost:9870`) mostrando **3 DataNodes vivos** | 10 |
| E2 | Salida de `ubicar_bloques.sh` (o de `hdfs fsck ... -locations`) para **el archivo de ventas de tu grupo** | 10 |
| E3 | Un bloque físico (`blk_...`) encontrado dentro de un DataNode con `find`, y sus primeras líneas con `head` | 4 o 10 |
| E4 | Resultado en `beeline` de la **consulta de negocio asignada a tu grupo** | 8 |
| E5 | `hdfs dfs -ls` del warehouse **antes y después** del `DROP` de la tabla administrada y de la externa | 9 |
| E6 | Estado del clúster con un DataNode apagado: nodo muerto en la UI y salida de `fsck` | 11 |

### 1.2 Preguntas de comprensión (respuestas de 2 a 5 líneas cada una, con tus palabras)

1. ¿Qué guarda el NameNode y qué guarda cada DataNode? Justifícalo con lo que encontraste dentro
   de los contenedores (qué archivos hay en `/data/dfs/name` y qué hay en `/data/dfs/data`).
2. Con tu salida de E2: ¿cuántos bloques tiene el archivo de tu grupo, en qué DataNodes está cada uno
   y por qué cada bloque aparece en dos nodos?
3. ¿En qué se diferencia `hdfs dfs -ls /datasets` de `ls /datasets` dentro del contenedor?
   ¿Dónde están "de verdad" los bytes del archivo?
4. ¿Qué pasó con los datos al hacer `DROP TABLE` de la tabla **externa** y qué pasó con los de la
   tabla **administrada**? ¿Por qué esa diferencia importa cuando varios equipos comparten un Data Lake?
5. Al apagar `datanode2`: ¿pudiste seguir leyendo tu archivo? ¿Qué hizo el NameNode después de
   ~1 minuto? Relaciónalo con la **P** (tolerancia a particiones) del teorema CAP.
6. El programa `WordCount.java` y la consulta de Hive dan el mismo resultado. ¿Qué gana y qué pierde
   un equipo que usa Hive en vez de escribir MapReduce a mano?

### 1.3 Mini-reto del grupo

Cada grupo recibe por **sorteo en clase** una de estas preguntas de negocio, y la responde con una
consulta en Hive sobre **su** archivo `ventas_G#.csv`. El grupo puede escribir la consulta junto, pero cada
estudiante la ejecuta en su laptop e incluye en su bitácora la consulta, el resultado y su interpretación.

| Reto | Pregunta de negocio |
|---|---|
| A | Ventas totales (`cantidad * precio_unitario`) por **país**, ordenadas de mayor a menor. ¿Cuál país concentra más ventas? |
| B | Los **5 productos** con más unidades vendidas. ¿Cuántas unidades vendió el primero? |
| C | Ventas totales por **mes** (`substr(fecha, 1, 7)`). ¿Cuál fue el mejor mes y cuál el peor? |
| D | **Ticket promedio** por canal (`tienda`, `web`, `app`) y número de ventas por canal. ¿Qué canal tiene el ticket más alto? |

### Rúbrica de la bitácora

| Criterio | Puntos (de 40) |
|---|---|
| Las 6 evidencias están completas, legibles y son tuyas (tomadas en tu máquina) | 12 |
| Las 6 preguntas se responden con lo observado, con tus palabras (no definiciones copiadas) | 18 |
| Mini-reto: consulta correcta y resultado interpretado en una frase | 10 |

Bitácoras con capturas o respuestas idénticas entre integrantes se califican como una sola y el puntaje se
divide entre ellas.

### Cómo se entrega

En el repo privado del curso, `github.com/jcarriolaa/BigData-2026-S2-entregas`, con una **rama por estudiante**
y un **Pull Request** que marca la entrega. La guía paso a paso, con checkpoints, está en
[`entrega-git.md`](entrega-git.md). En resumen:

| Qué | Cómo |
|---|---|
| Rama | `entrega-<carné>-<nombre>-<apellido>`, en minúsculas y sin tildes. Ej.: `entrega-20231234-ana-morales` |
| Carpeta | `entregas/G#/<carné>-<nombre>-<apellido>/`. No se toca nada fuera de ella |
| Contenido | `bitacora.md`, `capturas/E1..E6` (PNG/JPG, máx. 1 MB c/u), `consultas.sql`, `docker-compose.yml`, `config/`, `check.txt` |
| Entrega | Un Pull Request de tu rama contra `main`, título `Entrega G# - Nombre Apellido`. Sin *merge* |
| Portal | Se sube la URL del PR |

`docker-compose.yml`, `config/` y `check.txt` no dan puntos por sí mismos: son la prueba de que el entorno es tuyo.
La nota y los comentarios quedan en el PR.

## 2. Defensa oral (60 %, por grupo con partes individuales)

En una clase posterior al taller (fecha anunciada en clase), cada grupo pasa al frente. El taller se divide en
**partes** y a **cada integrante le toca una distinta**, por sorteo en el momento:

| Parte | Pasos | Qué se demuestra en vivo |
|---|---|---|
| P1 | 3 y 4 | Levantar HDFS, subir un archivo, ubicar sus bloques con `fsck` y encontrar uno físicamente en el DataNode |
| P2 | 5 y 8 | Correr el `wordcount` de MapReduce y la misma consulta en Hive; explicar el `EXPLAIN` |
| P3 | 7 y 9 | Crear una tabla externa, crear una administrada, hacer `DROP` de ambas y mostrar qué pasó en HDFS |
| P4 | 10 y 11 | Escalar a 3 DataNodes, subir la replicación, apagar un nodo y mostrar la recuperación |

Cada integrante tiene **3 minutos** para su parte, en su propia laptop, con el entorno ya levantado. Como no sabes
qué parte te va a tocar, tienes que poder hacer las cuatro. Después de las demostraciones, el catedrático hace
preguntas a cualquier integrante sobre cualquier parte.

Si el grupo tiene más de cuatro integrantes, dos comparten la parte P4 (uno escala, otro apaga el nodo). Si tiene
menos, una persona hace dos partes.

### Rúbrica de la defensa

| Criterio | Quién | Puntos (de 60) |
|---|---|---|
| Tu parte corre en tu laptop y explicas qué hace cada comando mientras lo ejecutas | Individual | 30 |
| Respondes preguntas con precisión técnica (bloques, réplicas, NameNode, tablas externas) | Individual | 20 |
| El grupo conecta lo observado con la teoría del curso (GFS/MapReduce, CAP, schema-on-read) | Grupo | 10 |

Si tu entorno no corre en el momento, puedes usar la laptop de un compañero con una penalización de 10 puntos
en tu parte individual.

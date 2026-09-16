# Entregable y evaluación del taller

El taller se califica sobre **100 %** en dos partes. El peso final dentro del rubro "Tareas y prácticas"
se comunica al cierre del semestre.

| Parte | Peso | Qué es |
|---|---|---|
| Bitácora del grupo | 40 % | Documento corto con evidencias y respuestas (este archivo, llenado) |
| Defensa oral | 60 % | Demostración en vivo de un paso sorteado y preguntas del catedrático |

## 1. Bitácora del grupo (40 %)

Un solo archivo por grupo, en **PDF o Markdown**, con el nombre `bitacora_G#.pdf`.
**Fecha de entrega:** la fecha de la defensa oral se anuncia en clase; la bitácora se entrega **antes de que empiece
esa clase**, por el medio que indique el catedrático. Entregas tardías se evalúan solo con la defensa oral.
No es un informe: es evidencia de que lo corrieron y de que entendieron lo que vieron.
Extensión sugerida: 4 a 6 páginas con capturas.

### 1.1 Evidencias (capturas de pantalla)

Cada captura debe verse completa y legible. Si es de terminal, que se vea el comando y la salida.

| # | Evidencia | Paso |
|---|---|---|
| E1 | Interfaz del NameNode (`localhost:9870`) mostrando **3 DataNodes vivos** | 10 |
| E2 | Salida de `ubicar_bloques.sh` (o de `hdfs fsck ... -locations`) para **el archivo de ventas de su grupo** | 10 |
| E3 | Un bloque físico (`blk_...`) encontrado dentro de un DataNode con `find`, y sus primeras líneas con `head` | 4 o 10 |
| E4 | Resultado en `beeline` de la **consulta de negocio asignada a su grupo** | 8 |
| E5 | `hdfs dfs -ls` del warehouse **antes y después** del `DROP` de la tabla administrada y de la externa | 9 |
| E6 | Estado del clúster con un DataNode apagado: nodo muerto en la UI y salida de `fsck` | 11 |

### 1.2 Preguntas de comprensión (respuestas de 2 a 5 líneas cada una)

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
consulta en Hive sobre **su** archivo `ventas_G#.csv`. En la bitácora van la consulta y el resultado.

| Reto | Pregunta de negocio |
|---|---|
| A | Ventas totales (`cantidad * precio_unitario`) por **país**, ordenadas de mayor a menor. ¿Cuál país concentra más ventas? |
| B | Los **5 productos** con más unidades vendidas. ¿Cuántas unidades vendió el primero? |
| C | Ventas totales por **mes** (`substr(fecha, 1, 7)`). ¿Cuál fue el mejor mes y cuál el peor? |
| D | **Ticket promedio** por canal (`tienda`, `web`, `app`) y número de ventas por canal. ¿Qué canal tiene el ticket más alto? |

### Rúbrica de la bitácora

| Criterio | Puntos (de 40) |
|---|---|
| Las 6 evidencias están completas, legibles y corresponden a su grupo | 12 |
| Las 6 preguntas se responden con lo observado (no con definiciones copiadas) | 18 |
| Mini-reto: consulta correcta y resultado interpretado en una frase | 10 |

## 2. Defensa oral (60 %)

En una clase posterior al taller (fecha anunciada en clase), cada grupo pasa **8 minutos**:

1. Se sortea **un paso** del taller (del 4 al 11) y **un integrante** que lo demuestra en vivo en su
   laptop. Cualquier integrante puede salir sorteado, así que todos deben tener el entorno funcionando.
2. El catedrático hace preguntas al grupo sobre la bitácora y sobre lo que se ve en pantalla.

### Rúbrica de la defensa

| Criterio | Puntos (de 60) |
|---|---|
| El paso sorteado corre y el integrante explica qué hace cada comando | 25 |
| Responden preguntas con precisión técnica (bloques, réplicas, NameNode, tablas externas) | 25 |
| Conectan lo observado con la teoría del curso (GFS/MapReduce, CAP, schema-on-read) | 10 |

Si el entorno no corre en la máquina sorteada, el grupo puede usar la de otro integrante con una
penalización de 10 puntos.

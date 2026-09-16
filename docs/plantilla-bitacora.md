# Bitácora del taller Hadoop y Hive

- **Nombre:**
- **Carné:**
- **Grupo:** G#
- **Mini-reto asignado al grupo:** A / B / C / D
- **Sistema operativo y chip de tu laptop:** (ej. macOS, Apple M2 / Windows 11, Intel)

> Copia este archivo como `bitacora.md` dentro de tu carpeta de entrega y llena cada sección.
> Las capturas van en la carpeta `capturas/` y se enlazan desde aquí. Borra las líneas de ayuda en `>` antes de entregar.

## 1. Evidencias

> Cada captura debe verse completa, con el comando y su salida. Debajo de cada una escribe **una frase** con lo que muestra.

### E1. NameNode con 3 DataNodes vivos (Paso 10)

![E1](capturas/E1-namenode-3-datanodes.png)

Lo que muestra:

### E2. Ubicación de los bloques del archivo de mi grupo (Paso 10)

![E2](capturas/E2-ubicar-bloques.png)

Lo que muestra:

### E3. Un bloque físico dentro de un DataNode (Paso 4 o 10)

![E3](capturas/E3-bloque-fisico.png)

Lo que muestra:

### E4. Resultado de la consulta de negocio de mi grupo (Paso 8)

![E4](capturas/E4-consulta-negocio.png)

Lo que muestra:

### E5. Warehouse antes y después del `DROP` (Paso 9)

![E5](capturas/E5-drop-antes-despues.png)

Lo que muestra:

### E6. Clúster con un DataNode apagado (Paso 11)

![E6](capturas/E6-nodo-caido.png)

Lo que muestra:

## 2. Preguntas de comprensión

> 2 a 5 líneas por respuesta, con tus palabras y con lo que viste en tu máquina. No copies definiciones.

**1. ¿Qué guarda el NameNode y qué guarda cada DataNode?** Justifícalo con lo que encontraste en `/data/dfs/name` y en `/data/dfs/data`.



**2. Con tu salida de E2: ¿cuántos bloques tiene el archivo de tu grupo, en qué DataNodes está cada uno y por qué cada bloque aparece en dos nodos?**



**3. ¿En qué se diferencia `hdfs dfs -ls /datasets` de `ls /datasets` dentro del contenedor? ¿Dónde están "de verdad" los bytes del archivo?**



**4. ¿Qué pasó con los datos al hacer `DROP TABLE` de la tabla externa y qué pasó con los de la administrada? ¿Por qué esa diferencia importa cuando varios equipos comparten un Data Lake?**



**5. Al apagar `datanode2`: ¿pudiste seguir leyendo tu archivo? ¿Qué hizo el NameNode después de ~1 minuto? Relaciónalo con la P del teorema CAP.**



**6. `WordCount.java` y la consulta de Hive dan el mismo resultado. ¿Qué gana y qué pierde un equipo que usa Hive en vez de escribir MapReduce a mano?**



## 3. Mini-reto del grupo

**Pregunta de negocio (reto ___):**

**Consulta:**

```sql

```

**Resultado (pega la tabla que devolvió beeline):**

```

```

**Interpretación en una frase:**

## 4. Problemas que tuve y cómo los resolví (opcional)

> Si te atoraste en algún paso, cuenta el error exacto y qué lo arregló. Sirve para mejorar la guía y no resta puntos.

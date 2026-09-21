// WordCount.java: el "hola mundo" de MapReduce.
//
// NO hay que compilarlo ni ejecutarlo. Está aquí para LEERLO mientras corre el
// mismo programa (ya compilado dentro de la imagen de Hadoop) en el Paso 5, y para
// compararlo con la consulta de una línea que hace lo mismo en Hive (Paso 8).
//
// Idea general (paper "MapReduce: Simplified Data Processing on Large Clusters", Google 2004):
//   1. MAP:     cada mapper recibe UNA línea del archivo y emite pares (palabra, 1).
//   2. SHUFFLE: Hadoop agrupa todos los pares por clave -> (palabra, [1, 1, 1, ...]).
//   3. REDUCE:  cada reducer recibe una palabra con su lista de unos y los suma.
//
// Con un archivo de 5 bloques en 3 DataNodes, Hadoop lanza un mapper por bloque, cerca de
// donde vive el bloque ("mover el cómputo a los datos, no los datos al cómputo").

import java.io.IOException;
import java.util.StringTokenizer;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class WordCount {

  // ---------- FASE MAP ----------
  // Entrada:  (posición en el archivo, línea de texto)
  // Salida:   (palabra, 1) por cada palabra de la línea
  public static class TokenizerMapper extends Mapper<Object, Text, Text, IntWritable> {

    private final static IntWritable UNO = new IntWritable(1);
    private Text palabra = new Text();

    @Override
    public void map(Object clave, Text linea, Context contexto)
        throws IOException, InterruptedException {
      StringTokenizer tokens = new StringTokenizer(linea.toString());
      while (tokens.hasMoreTokens()) {
        palabra.set(tokens.nextToken());
        contexto.write(palabra, UNO);          // emite (palabra, 1)
      }
    }
  }

  // ---------- FASE REDUCE ----------
  // Entrada:  (palabra, [1, 1, 1, ...])   <- Hadoop ya agrupó por palabra (shuffle)
  // Salida:   (palabra, total)
  public static class IntSumReducer extends Reducer<Text, IntWritable, Text, IntWritable> {

    private IntWritable resultado = new IntWritable();

    @Override
    public void reduce(Text palabra, Iterable<IntWritable> valores, Context contexto)
        throws IOException, InterruptedException {
      int suma = 0;
      for (IntWritable v : valores) {
        suma += v.get();
      }
      resultado.set(suma);
      contexto.write(palabra, resultado);      // emite (palabra, total)
    }
  }

  // ---------- CONFIGURACIÓN DEL JOB ----------
  // Aquí se dice a Hadoop qué clases usar, de dónde leer y dónde escribir.
  public static void main(String[] args) throws Exception {
    Configuration conf = new Configuration();
    Job job = Job.getInstance(conf, "word count");
    job.setJarByClass(WordCount.class);
    job.setMapperClass(TokenizerMapper.class);
    job.setCombinerClass(IntSumReducer.class);   // optimización: suma parcial en el mapper
    job.setReducerClass(IntSumReducer.class);
    job.setOutputKeyClass(Text.class);
    job.setOutputValueClass(IntWritable.class);
    FileInputFormat.addInputPath(job, new Path(args[0]));    // carpeta de entrada en HDFS
    FileOutputFormat.setOutputPath(job, new Path(args[1]));  // carpeta de salida en HDFS (no debe existir)
    System.exit(job.waitForCompletion(true) ? 0 : 1);
  }
}

// Compara con Hive, que produce exactamente el mismo resultado:
//
//   SELECT palabra, COUNT(*) AS total
//   FROM word_count LATERAL VIEW explode(split(linea, ' ')) t AS palabra
//   GROUP BY palabra;
//
// Hive traduce esa consulta a un plan con una fase Map y una fase Reduce (puedes verlo
// con EXPLAIN). No reemplaza a MapReduce: lo esconde detrás de SQL.

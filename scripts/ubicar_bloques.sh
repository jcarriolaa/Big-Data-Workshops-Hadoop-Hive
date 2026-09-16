#!/usr/bin/env bash
# Muestra en qué DataNode(s) vive cada bloque de un archivo de HDFS, usando el nombre
# del contenedor en vez de la IP. Se ejecuta DENTRO del NameNode:
#
#   docker exec namenode bash /scripts/ubicar_bloques.sh /datasets/ventas/ventas_G1.csv
#
# Por debajo combina dos comandos que también puedes correr a mano:
#   hdfs dfsadmin -report          -> lista de DataNodes con su IP y hostname
#   hdfs fsck <ruta> -files -blocks -locations -> bloques del archivo y la IP donde está cada réplica

RUTA="${1:?Uso: ubicar_bloques.sh /ruta/en/hdfs}"

# Mapa "IP hostname" a partir del reporte de DataNodes.
MAPA=$(hdfs dfsadmin -report 2>/dev/null \
  | awk '/^Name:/ {ip=$2; sub(/:.*/, "", ip)} /^Hostname:/ {print ip, $2}')

echo "Archivo HDFS: $RUTA"
echo "Bloque                      Tamaño (bytes)   DataNodes con una copia"
echo "--------------------------  ---------------  ------------------------"

hdfs fsck "$RUTA" -files -blocks -locations 2>/dev/null \
  | grep -E '^[0-9]+\. ' \
  | while read -r linea; do
      bloque=$(grep -oE 'blk_[0-9]+' <<<"$linea" | head -1)
      tam=$(grep -oE 'len=[0-9]+' <<<"$linea" | cut -d= -f2)
      nodos=""
      for ip in $(grep -oE '\[[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' <<<"$linea" | tr -d '['); do
        nombre=$(awk -v ip="$ip" '$1==ip {print $2}' <<<"$MAPA")
        nodos="$nodos ${nombre:-$ip}"
      done
      printf '%-26s  %15s  %s\n' "$bloque" "$tam" "$nodos"
    done

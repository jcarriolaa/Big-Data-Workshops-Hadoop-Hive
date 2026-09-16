#!/usr/bin/env bash
# Autovalidación del taller. Uso:
#   scripts/check.sh prereq    # antes de la clase: Docker, RAM e imágenes
#   scripts/check.sh hdfs      # después del Paso 4: HDFS con datos cargados
#   scripts/check.sh hive      # después del Paso 7: Hive con las tablas externas
#   scripts/check.sh cluster   # después del Paso 10: 3 DataNodes y réplicas
# En Windows ejecútalo desde Git Bash o WSL.

FALLOS=0
ok()   { echo "✅ $1"; }
fail() { echo "❌ $1"; FALLOS=$((FALLOS + 1)); }

corriendo() { [ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = "true" ]; }
datanodes_vivos() {
  docker exec namenode hdfs dfsadmin -report 2>/dev/null | grep -m1 'Live datanodes' | grep -oE '[0-9]+'
}

case "${1:-prereq}" in
  prereq)
    command -v docker >/dev/null 2>&1 \
      && ok "Docker instalado: $(docker --version)" \
      || fail "Docker no está en el PATH. Instala Docker Desktop."
    docker compose version >/dev/null 2>&1 \
      && ok "Docker Compose v2: $(docker compose version --short)" \
      || fail "'docker compose' (v2) no responde. Actualiza Docker Desktop."
    docker info >/dev/null 2>&1 \
      && ok "Docker Desktop está corriendo" \
      || fail "Docker no responde. Abre Docker Desktop y espera a que diga 'running'."
    mem=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0)
    gb=$((mem / 1024 / 1024 / 1024))
    [ "$gb" -ge 6 ] \
      && ok "RAM asignada a Docker: ${gb} GB" \
      || fail "RAM asignada a Docker: ${gb} GB. El taller necesita 6 GB (Settings > Resources)."
    for img in apache/hadoop:3.4.1 apache/hive:4.0.0; do
      docker image inspect "$img" >/dev/null 2>&1 \
        && ok "Imagen $img descargada" \
        || fail "Falta la imagen $img. Ejecuta: docker pull $img"
    done
    ;;

  hdfs)
    for c in namenode datanode1; do
      corriendo "$c" && ok "Contenedor $c corriendo" || fail "Contenedor $c no está corriendo (docker compose ps)"
    done
    vivos=$(datanodes_vivos)
    [ "${vivos:-0}" -ge 1 ] \
      && ok "DataNodes vivos según el NameNode: $vivos" \
      || fail "El NameNode no ve DataNodes vivos. Revisa: docker compose logs datanode1"
    for d in /datasets/empleados /datasets/word_count /datasets/ventas; do
      docker exec namenode hdfs dfs -test -d "$d" 2>/dev/null \
        && ok "Existe $d en HDFS" \
        || fail "No existe $d en HDFS (Paso 4)"
    done
    salud=$(docker exec namenode hdfs fsck /datasets 2>/dev/null | grep -oE 'is (HEALTHY|CORRUPT)')
    [ "$salud" = "is HEALTHY" ] && ok "fsck /datasets: HEALTHY" || fail "fsck /datasets no reporta HEALTHY"
    ;;

  hive)
    corriendo hiveserver2 && ok "Contenedor hiveserver2 corriendo" || fail "hiveserver2 no está corriendo"
    tablas=$(docker exec hiveserver2 beeline -u jdbc:hive2://localhost:10000 --silent=true \
               --outputformat=csv2 -e 'SHOW TABLES;' 2>/dev/null | tail -n +2)
    for t in empleados word_count ventas; do
      grep -qx "$t" <<<"$tablas" && ok "Tabla $t existe en Hive" || fail "Falta la tabla $t en Hive (Paso 7)"
    done
    ;;

  cluster)
    for c in namenode datanode1 datanode2 datanode3; do
      corriendo "$c" && ok "Contenedor $c corriendo" || fail "Contenedor $c no está corriendo"
    done
    vivos=$(datanodes_vivos)
    [ "${vivos:-0}" -ge 3 ] \
      && ok "DataNodes vivos según el NameNode: $vivos" \
      || fail "El NameNode ve ${vivos:-0} DataNodes; se esperan 3 (espera 30 s y reintenta)"
    repl=$(docker exec namenode hdfs fsck /datasets/ventas 2>/dev/null | grep -oE 'Average block replication:\s*[0-9.]+' | grep -oE '[0-9.]+$')
    awk -v r="${repl:-0}" 'BEGIN {exit !(r >= 2)}' \
      && ok "Replicación promedio en /datasets/ventas: $repl" \
      || fail "Replicación promedio en /datasets/ventas: ${repl:-?} (se espera 2; revisa hdfs dfs -setrep)"
    ;;

  *)
    echo "Uso: scripts/check.sh [prereq|hdfs|hive|cluster]"; exit 2 ;;
esac

echo
[ "$FALLOS" -eq 0 ] && echo "Todo en orden." || echo "$FALLOS problema(s). Revisa la sección '❌ Si falla' del paso correspondiente."
exit "$FALLOS"

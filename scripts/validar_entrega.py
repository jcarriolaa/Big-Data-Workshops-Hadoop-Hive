#!/usr/bin/env python3
"""Valida la estructura de una entrega del taller antes de abrir (o al abrir) el Pull Request.

Corre en GitHub Actions sobre cada PR y también en tu laptop:

    python3 scripts/validar_entrega.py entregas/G3/20231234-ana-morales

Revisa lo mecánico (carpeta, archivos, capturas, check.txt, que las respuestas no estén vacías).
NO califica: la calidad de las respuestas la evalúa el catedrático.
Termina con código 1 si hay algún ❌.
"""
import os
import re
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
MAX_IMG = 1_000_000
CAPTURAS = ["E1", "E2", "E3", "E4", "E5", "E6"]
ARCHIVOS = ["bitacora.md", "consultas.sql", "docker-compose.yml", "check.txt",
            "config/hadoop/core-site.xml", "config/hadoop/hdfs-site.xml", "config/hive/hive-site.xml"]
PREGUNTAS = 6
MIN_PALABRAS = 15
AYUDAS = ["Copia este archivo como", "Borra las líneas de ayuda", "Cada captura debe verse completa",
          "2 a 5 líneas por respuesta", "Si te atoraste en algún paso"]
# Texto de la plantilla que va después del enunciado en negrita y no es respuesta del estudiante
COLAS_ENUNCIADO = ["Justifícalo con lo que encontraste en `/data/dfs/name` y en `/data/dfs/data`."]

resultados = []  # (estado, nombre, detalle)


def ok(n, d=""):   resultados.append(("✅", n, d))
def warn(n, d=""): resultados.append(("⚠️", n, d))
def fail(n, d=""): resultados.append(("❌", n, d))


def git(*args):
    try:
        return subprocess.check_output(["git", "-C", str(RAIZ), *args], text=True, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def archivos_cambiados():
    base = os.environ.get("BASE_REF", "origin/main")
    out = git("diff", "--name-only", f"{base}...HEAD")
    if out is None:
        out = git("diff", "--name-only", "main...HEAD")
    return None if out is None else out.split()


def main():
    # 1. ¿Qué carpeta se revisa? Argumento explícito, o la que cambia el PR.
    cambiados = archivos_cambiados()
    if len(sys.argv) > 1:
        carpeta = sys.argv[1].strip("/")
    else:
        if cambiados is None:
            print("No pude calcular los archivos cambiados. Pasa la carpeta: python3 scripts/validar_entrega.py entregas/G#/<carpeta>")
            return 2
        carpetas = sorted({"/".join(p.split("/")[:3]) for p in cambiados
                           if p.startswith("entregas/") and p.count("/") >= 3})
        if not carpetas:
            print("Este PR no toca entregas/: no hay entrega que validar. ✅")
            return 0
        if len(carpetas) > 1:
            fail("T1 carpeta", f"el PR toca varias carpetas de entrega: {carpetas}")
        carpeta = carpetas[0]

    m = re.match(r"^entregas/(G[1-4])/(\d+)-([a-z]+)-([a-z]+)$", carpeta)
    if m:
        ok("T1 carpeta", carpeta)
    else:
        fail("T1 carpeta", f"`{carpeta}` no sigue entregas/G#/<carné>-<nombre>-<apellido> (minúsculas, sin tildes)")
    grupo = carpeta.split("/")[1] if carpeta.count("/") >= 2 else "?"
    dir_ = RAIZ / carpeta
    if not dir_.is_dir():
        fail("T1 carpeta", f"`{carpeta}` no existe")
        return terminar()

    # 2. Nada fuera de la carpeta
    if cambiados is not None:
        fuera = [p for p in cambiados if not p.startswith(carpeta + "/")]
        if fuera:
            fail("T2 solo tu carpeta", "el PR toca archivos fuera de tu carpeta: " + ", ".join(fuera[:8])
                 + (" …" if len(fuera) > 8 else "") + ". Quítalos con `git rm -r --cached <archivo>`, commit y push.")
        else:
            ok("T2 solo tu carpeta")

    # 3. Nombre de rama
    rama = os.environ.get("RAMA") or (git("branch", "--show-current") or "").strip()
    if rama:
        if re.match(r"^entrega-\d+-[a-z]+-[a-z]+$", rama):
            ok("T3 rama", rama)
        else:
            warn("T3 rama", f"`{rama}`: se esperaba entrega-<carné>-<nombre>-<apellido> en minúsculas")

    # 4. Archivos obligatorios
    faltan = [a for a in ARCHIVOS if not (dir_ / a).exists()]
    if faltan:
        fail("T4 archivos", "faltan: " + ", ".join(faltan))
    else:
        ok("T4 archivos", "los 7 archivos están")

    # 5. Capturas
    cap = dir_ / "capturas"
    for e in CAPTURAS:
        cands = sorted(cap.glob(f"{e}*")) if cap.is_dir() else []
        if not cands:
            fail(f"T5 captura {e}", "no existe en capturas/")
            continue
        for c in cands:
            b = c.read_bytes()
            if not (b[:8] == b"\x89PNG\r\n\x1a\n" or b[:3] == b"\xff\xd8\xff"):
                fail(f"T5 captura {e}", f"{c.name} no es PNG ni JPG")
            elif len(b) > MAX_IMG:
                fail(f"T5 captura {e}", f"{c.name} pesa {len(b)/1e6:.1f} MB; máximo 1 MB")
            else:
                ok(f"T5 captura {e}", f"{c.name} ({len(b)//1024} KB)")

    # 6. check.txt
    chk = (dir_ / "check.txt").read_text(errors="replace") if (dir_ / "check.txt").exists() else ""
    c_ok = "DataNodes vivos según el NameNode: 3" in chk
    h_ok = "Tabla ventas existe en Hive" in chk
    if c_ok and h_ok and "❌" not in chk:
        ok("T6 check.txt", "cluster y hive en verde")
    else:
        det = [x for x, v in [("falta la salida de `check.sh cluster`", c_ok), ("falta la salida de `check.sh hive`", h_ok)] if not v]
        if "❌" in chk: det.append("hay líneas con ❌")
        warn("T6 check.txt", "; ".join(det))

    # 7. hdfs-site.xml
    hs = dir_ / "config/hadoop/hdfs-site.xml"
    if hs.exists():
        x = re.sub(r"\s+", "", hs.read_text(errors="replace"))
        rep = re.search(r"<name>dfs\.replication</name><value>(\d+)</value>", x)
        blk = re.search(r"<name>dfs\.blocksize</name><value>(\d+)</value>", x)
        if rep and rep.group(1) == "2" and blk and blk.group(1) == "1048576":
            ok("T7 hdfs-site", "replication=2, blocksize=1 MB")
        else:
            warn("T7 hdfs-site", f"replication={rep.group(1) if rep else '?'}, blocksize={blk.group(1) if blk else '?'} (se esperaba 2 y 1048576)")

    # 8. Bitácora
    bp = dir_ / "bitacora.md"
    if bp.exists():
        bit = bp.read_text(errors="replace")
        ay = [a for a in AYUDAS if a in bit]
        if ay:
            warn("T8 plantilla", f"quedaron {len(ay)} textos de ayuda de la plantilla sin borrar")
        else:
            ok("T8 plantilla", "sin textos de ayuda")
        for i in range(1, PREGUNTAS + 1):
            mm = re.search(rf"\*\*{i}\.\s.*?\*\*(.*?)(?=\n\*\*{i+1}\.\s|\n## |\Z)", bit, re.S)
            t = (mm.group(1) if mm else "").strip()
            for cola in COLAS_ENUNCIADO:
                t = t.replace(cola, "")
            t = "\n".join(l for l in t.splitlines() if not l.strip().startswith(">")).strip()
            n = len(t.split())
            if n < MIN_PALABRAS:
                fail(f"T8 pregunta {i}", f"{n} palabras: está vacía o incompleta")
            else:
                ok(f"T8 pregunta {i}", f"{n} palabras")
        sec = re.search(r"## 3\..*?(?=\n## |\Z)", bit, re.S)
        sec = sec.group(0) if sec else ""
        sql = re.search(r"```\w*\s*\n(.*?)```", sec, re.S)
        res = re.search(r"Resultado.*?```\w*\s*\n(.*?)```", sec, re.S)
        inter = re.search(r"Interpretaci[oó]n[^\n]*:\**\s*\n*(.+)", sec)
        partes = [("consulta", sql and len(sql.group(1).strip()) > 20),
                  ("resultado", res and len(res.group(1).strip()) > 10),
                  ("interpretación", inter and len(inter.group(1).strip()) > 15)]
        faltan = [p for p, v in partes if not v]
        if faltan:
            fail("T9 mini-reto", "falta: " + ", ".join(faltan))
        else:
            ok("T9 mini-reto", "consulta, resultado e interpretación presentes")
        vs = sorted(set(re.findall(r"ventas_(G[1-4])", bit + ((dir_ / "consultas.sql").read_text(errors="replace") if (dir_ / "consultas.sql").exists() else ""))))
        if vs and vs != [grupo]:
            warn("T10 dataset", f"mencionas {vs} y tu grupo es {grupo}")
    else:
        fail("T8 bitácora", "no existe bitacora.md")

    return terminar(carpeta)


def terminar(carpeta="?"):
    fails = sum(1 for e, _, _ in resultados if e == "❌")
    warns = sum(1 for e, _, _ in resultados if e == "⚠️")
    lineas = [f"## Validación de `{carpeta}`", "",
              f"**{len(resultados) - fails - warns} ✅ · {warns} ⚠️ · {fails} ❌**", "",
              "| | Verificación | Detalle |", "|---|---|---|"]
    lineas += [f"| {e} | {n} | {d} |" for e, n, d in resultados]
    lineas += ["", "Los ⚠️ no bloquean; los ❌ hay que corregirlos antes de que se califique. "
               "Guía: docs/entrega-git.md · Qué se pide: docs/entregable.md"]
    salida = "\n".join(lineas)
    print(salida)
    resumen = os.environ.get("GITHUB_STEP_SUMMARY")
    if resumen:
        with open(resumen, "a") as f:
            f.write(salida + "\n")
    archivo = os.environ.get("SALIDA_MD")
    if archivo:
        Path(archivo).write_text(salida + "\n")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())

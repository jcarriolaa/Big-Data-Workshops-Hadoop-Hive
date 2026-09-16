# Cómo entregar la bitácora con git

La entrega se hace en **este mismo repositorio** (el del taller, que ya clonaste en el Paso 0.2), con una **rama**
por estudiante, una carpeta dentro de `entregas/` y un **Pull Request** (PR) que marca que terminaste.

Son cinco pasos. Si nunca has usado git, calcula 20 minutos la primera vez.

## Qué es cada cosa

- **Repositorio (repo):** una carpeta con historial de cambios, alojada en GitHub. Es el del taller:
  `github.com/jcarriolaa/Big-Data-Workshops-Hadoop-Hive`.
- **Rama (branch):** una copia de trabajo dentro del repo. Tú trabajas en la tuya y no tocas la de nadie.
- **Commit:** una "foto" de tus archivos con un mensaje. Puedes hacer varios.
- **Push:** subir tus commits a GitHub.
- **Pull Request (PR):** el sobre de entrega. Le dice al catedrático "mi rama está lista para revisar". No hay que
  hacer *merge*; el PR queda abierto y ahí se califica.

## Paso 1: Prepara git y tu acceso

1. Instala git si no lo tienes: [git-scm.com/downloads](https://git-scm.com/downloads). En Mac también sirve
   `xcode-select --install`. En Windows instala **Git for Windows** (trae Git Bash).
2. Crea una cuenta en [github.com](https://github.com) si no tienes, y manda tu usuario de GitHub al catedrático
   por el medio que indique. Él te agrega como colaborador y GitHub te manda una invitación por correo
   (*"jcarriolaa invited you to collaborate"*): **acéptala**. Sin eso, puedes leer el repo pero no subir tu rama.
3. Configura tu nombre y correo (una sola vez en tu laptop):

```bash
git config --global user.name "Ana Morales"
git config --global user.email "tu-correo@ejemplo.com"
```

### ✅ Checkpoint

```bash
git --version
```

```
git version 2.4x.x
```

Y en GitHub, con tu sesión iniciada, en <https://github.com/jcarriolaa/Big-Data-Workshops-Hadoop-Hive> debes aparecer
como colaborador: si aceptaste la invitación, el repo te muestra el botón de *Watch/Unwatch* normal y, en
*Settings → Collaborators* del catedrático, tu usuario. La forma más simple de comprobarlo es el Paso 4: si el
`push` funciona, estás dentro.

## Paso 2: Crea tu rama

No hay que clonar nada nuevo: usas la carpeta del taller que ya tienes. El nombre de la rama es
`entrega-<carné>-<nombre>-<apellido>`, todo en minúsculas, sin tildes ni espacios.

```bash
cd Big-Data-Workshops-Hadoop-Hive                 # <- la carpeta del taller
git checkout main
git pull
git checkout -b entrega-20231234-ana-morales      # <- con tu carné y tu nombre
```

Si descargaste el taller como ZIP en vez de clonarlo, primero clónalo:
`git clone https://github.com/jcarriolaa/Big-Data-Workshops-Hadoop-Hive.git` y copia ahí tu `docker-compose.yml`
y tu `config/`.

### ✅ Checkpoint

```bash
git branch --show-current
```

```
entrega-20231234-ana-morales
```

### ❌ Si falla

| Síntoma | Causa y arreglo |
|---|---|
| `git pull` dice que hay cambios locales sin guardar | Son tu `docker-compose.yml` y tu `config/`: son tuyos y no estorban. Si el error persiste, `git stash`, `git pull`, `git stash pop`. |
| Te pide contraseña y la rechaza | GitHub no acepta la contraseña de la cuenta por git. Usa el inicio de sesión del navegador que ofrece Git Credential Manager (Windows/Mac lo traen), o crea un *personal access token* en GitHub → Settings → Developer settings. |
| `fatal: A branch named ... already exists` | Ya la creaste antes. Solo cámbiate a ella: `git checkout entrega-...`. |

## Paso 3: Crea tu carpeta y copia tus archivos

Tu carpeta es `entregas/G#/<carné>-<nombre>-<apellido>/`. **No toques nada fuera de ella**: ni el README, ni
`data/`, ni `scripts/`, ni las carpetas de otros. Tu `docker-compose.yml` y tu `config/` de la raíz **no se suben**
tal cual; se copian dentro de tu carpeta.

```bash
mkdir -p entregas/G2/20231234-ana-morales/capturas      # <- tu grupo, tu carné, tu nombre
```

Copia dentro:

| Qué | De dónde | A dónde |
|---|---|---|
| Bitácora llena | `docs/plantilla-bitacora.md` del taller, copiada y llenada | `bitacora.md` |
| Las 6 capturas | tus imágenes (PNG o JPG, máximo 1 MB cada una) | `capturas/E1-....png` … `E6-....png` |
| Consultas | todo lo que corriste en beeline, incluido el mini-reto | `consultas.sql` |
| Tu compose | `docker-compose.yml` del taller (estado final, con 3 DataNodes y Hive) | `docker-compose.yml` |
| Tus XML | la carpeta `config/` completa del taller | `config/` |
| Autovalidación | salida de `bash scripts/check.sh cluster` y `bash scripts/check.sh hive`, pegada tal cual | `check.txt` |

Para `check.txt`, con el clúster levantado:

```bash
bash scripts/check.sh cluster >  entregas/G2/20231234-ana-morales/check.txt
bash scripts/check.sh hive    >> entregas/G2/20231234-ana-morales/check.txt
cp docker-compose.yml            entregas/G2/20231234-ana-morales/
cp -r config                     entregas/G2/20231234-ana-morales/
```

**No subas** los CSV de `data/`, ni volúmenes de Docker, ni archivos `.DS_Store`.

### ✅ Checkpoint

```bash
find entregas/G2/20231234-ana-morales -type f | sort
```

```
entregas/G2/20231234-ana-morales/bitacora.md
entregas/G2/20231234-ana-morales/capturas/E1-namenode-3-datanodes.png
entregas/G2/20231234-ana-morales/capturas/E2-ubicar-bloques.png
entregas/G2/20231234-ana-morales/capturas/E3-bloque-fisico.png
entregas/G2/20231234-ana-morales/capturas/E4-consulta-negocio.png
entregas/G2/20231234-ana-morales/capturas/E5-drop-antes-despues.png
entregas/G2/20231234-ana-morales/capturas/E6-nodo-caido.png
entregas/G2/20231234-ana-morales/check.txt
entregas/G2/20231234-ana-morales/config/hadoop/core-site.xml
entregas/G2/20231234-ana-morales/config/hadoop/hdfs-site.xml
entregas/G2/20231234-ana-morales/config/hive/hive-site.xml
entregas/G2/20231234-ana-morales/consultas.sql
entregas/G2/20231234-ana-morales/docker-compose.yml
```

## Paso 4: Commit y push

```bash
git add entregas/G2/20231234-ana-morales
git commit -m "Entrega taller Hadoop-Hive - Ana Morales"
git push -u origin entrega-20231234-ana-morales
```

La primera vez, git te pedirá iniciar sesión en GitHub (se abre el navegador o pide usuario y token). Sigue las
instrucciones en pantalla. Puedes repetir estos tres comandos las veces que quieras (por ejemplo, si corriges una respuesta). Cada `push`
actualiza tu rama.

### ✅ Checkpoint

```bash
git status
```

```
On branch entrega-20231234-ana-morales
Your branch is up to date with 'origin/entrega-20231234-ana-morales'.

nothing to commit, working tree clean
```

Y en GitHub, en el desplegable de ramas del repo, aparece la tuya.

### ❌ Si falla

| Síntoma | Causa y arreglo |
|---|---|
| `git add` dice `The following paths are ignored` | Estás intentando subir un archivo bloqueado (CSV grande, `.DS_Store`). No hace falta subirlo. |
| `Please tell me who you are` | Falta el Paso 1.3 (`git config --global user.name/email`). |
| `remote: error: File ... is 25.00 MB; this exceeds GitHub's file size limit` | Una captura o archivo demasiado grande. Comprímela o recórtala; máximo 1 MB por imagen. Quítala del commit con `git rm --cached <archivo>` y vuelve a commitear. |
| `git push` dice `main -> main` en vez de tu rama | Hiciste push a `main` por error. Avísale al catedrático de inmediato (se revierte sin problema) y revisa que estés en tu rama con `git branch --show-current`. |
| `Permission denied` / `403` / `remote: Write access to repository not granted` | No aceptaste la invitación de colaborador, o iniciaste sesión con otro usuario. Ver Paso 1.2. |
| `git status` muestra `docker-compose.yml` y `config/` de la raíz como cambios | Es normal: son tus archivos del taller. No los agregues al commit; solo `git add entregas/G#/<tu carpeta>`. |

## Paso 5: Abre el Pull Request

Esto se hace en el navegador:

1. Entra a <https://github.com/jcarriolaa/Big-Data-Workshops-Hadoop-Hive>. GitHub muestra un aviso amarillo
   *"entrega-... had recent pushes"* con el botón **Compare & pull request**. Haz clic. Si no aparece, pestaña
   **Pull requests → New pull request**, y en *compare* elige tu rama.
2. Título: `Entrega G2 - Ana Morales` (tu grupo y tu nombre).
3. En la descripción pega esta lista y marca lo que cumpliste:

```
- [ ] bitacora.md llena (6 evidencias, 6 respuestas, mini-reto)
- [ ] 6 capturas en capturas/
- [ ] consultas.sql
- [ ] docker-compose.yml y config/
- [ ] check.txt
- [ ] no toqué nada fuera de mi carpeta
```

4. Botón **Create pull request**. **No** hagas clic en *Merge*: el PR se queda abierto y ahí se califica.
5. Copia la URL del PR (algo como `.../pull/17`) y súbela al portal como tu entrega.

### ✅ Checkpoint

En la pestaña *Files changed* del PR solo aparecen archivos dentro de `entregas/G2/<tu carpeta>/`. Si aparece
algo más, quítalo de tu rama antes de que se califique.

### ❌ Si falla

| Síntoma | Causa y arreglo |
|---|---|
| No aparece el botón *Compare & pull request* | Tu `push` no llegó. Repite el Paso 4 y revisa que no haya error. |
| El PR muestra archivos de otras carpetas | Tocaste algo fuera de la tuya. Bórralo o restáuralo (`git checkout main -- <ruta>`), commit y push de nuevo. |
| Cerré el PR por error | Ábrelo de nuevo con el botón *Reopen* al final del PR. |

## Después de entregar

- El catedrático comenta en el PR, sobre las líneas de tu `bitacora.md` cuando aplique, y deja la nota de la
  bitácora en el comentario final.
- Si te pide corregir algo, edita los archivos, `git add`, `git commit`, `git push`: el PR se actualiza solo.
- No borres tu rama ni tu PR.

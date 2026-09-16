# Entregas

Aquí va la bitácora de cada estudiante, en su propia rama y su propia carpeta. La guía paso a paso está en
[`docs/entrega-git.md`](../docs/entrega-git.md); qué se califica, en [`docs/entregable.md`](../docs/entregable.md).

| Qué | Cómo |
|---|---|
| Rama | `entrega-<carné>-<nombre>-<apellido>`, en minúsculas y sin tildes. Ej.: `entrega-20231234-ana-morales` |
| Carpeta | `entregas/G#/<carné>-<nombre>-<apellido>/`. **No se toca nada fuera de ella** |
| Contenido | `bitacora.md`, `capturas/E1..E6` (PNG/JPG, máx. 1 MB c/u), `consultas.sql`, `docker-compose.yml`, `config/`, `check.txt` |
| Entrega | Un Pull Request de tu rama contra `main`, título `Entrega G# - Nombre Apellido`. **Sin merge** |
| Portal | Se sube la URL del PR |

Reglas:

1. **Nunca hagas push a `main`.** Trabaja siempre en tu rama.
2. **No toques la carpeta de otro estudiante** ni los archivos del taller (README, `data/`, `scripts/`, `docs/`).
3. **No subas** los CSV de `data/`, volúmenes de Docker ni archivos `.DS_Store`.
4. **No hagas merge ni borres tu rama.** El PR queda abierto y ahí se califica.

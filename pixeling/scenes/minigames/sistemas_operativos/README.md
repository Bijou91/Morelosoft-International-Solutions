# Materia: Sistemas Operativos y Linux (Aula 104)
**Responsable Base:** Héctor Varela Medina (Responsable de Calidad)

Esta carpeta aloja los minijuegos didácticos orientados al uso de la terminal GNU/Linux, gestión de archivos y procesos.

## Minijuegos del Módulo:
* `terminal_linux/`: **Terminal de Comandos Linux** (CU-16) - Desafíos interactivos de comandos bash (`cd`, `ls`, `mkdir`, `cat`).
* `exploracion_archivos/`: **Exploración del Sistema de Archivos** (CU-17) - Búsqueda y localización de flags en la jerarquía de directorios Linux mediante navegación, visualización de contenidos y envío de flags.
* `permisos_procesos/`: **Administrar Permisos y Procesos** (CU-18) - Administración y resolución de incidencias en un entorno GNU/Linux simulado y seguro mediante comandos bash (`ps`, `top`, `kill`, `chmod`, `chown`, `ls -l`), con pantalla dividida (terminal + objetivos) y teclado virtual táctil/físico.

## Reglas de Extensión (Escalabilidad sin Retrabajo):
1. Cada nuevo minijuego debe ubicarse en su propia subcarpeta con nombre semántico de alto nivel (`nombre_minijuego/`).
2. El script principal debe heredar de `MiniGameBase` (`extends MiniGameBase`).
3. Debe implementar `start_game(dificultad)` y llamar a `finish_game(exito, puntaje, estrellas)` al terminar.

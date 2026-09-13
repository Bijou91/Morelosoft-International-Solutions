# Materia: Sistemas Operativos y Linux (Aula 104)
**Responsable Base:** Héctor Varela Medina (Responsable de Calidad)

Esta carpeta aloja los minijuegos didácticos orientados al uso de la terminal GNU/Linux, gestión de archivos y procesos.

## Minijuegos del Módulo:
* `terminal_linux/`: **Terminal de Comandos Linux** - Desafíos interactivos de comandos bash (`cd`, `ls`, `mkdir`, `cat`).
* *(Futuro Sprint 2)* `permisos_chmod/`: Asignación interactiva de permisos rwx (octales y simbólicos) a usuarios y grupos.
* *(Futuro Sprint 3)* `procesos_pipes/`: Manipulación de pipes (`|`), redirecciones (`>`, `>>`) y señales de procesos.

## Reglas de Extensión (Escalabilidad sin Retrabajo):
1. Cada nuevo minijuego debe ubicarse en su propia subcarpeta con nombre semántico de alto nivel (`nombre_minijuego/`).
2. El script principal debe heredar de `MiniGameBase` (`extends MiniGameBase`).
3. Debe implementar `start_game(dificultad)` y llamar a `finish_game(exito, puntaje, estrellas)` al terminar.

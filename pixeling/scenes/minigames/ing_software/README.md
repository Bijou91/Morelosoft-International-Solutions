# Materia: Fundamentos de Ingeniería de Software (Aula 102)
**Responsable Base:** Karol Christopher Espino Galicia (Líder de Equipo)

Esta carpeta aloja los minijuegos didácticos asociados a la ingeniería de requisitos, ciclo de vida del software y metodologías ágiles/TSP.

## Minijuegos del Módulo:
* `lluvia_requerimientos/`: **Lluvia de Requerimientos** - El estudiante clasifica requerimientos funcionales y no funcionales en tiempo real.
* *(Futuro Sprint 2)* `casos_uso/`: Asociación interactiva de actores, precondiciones y flujos principales.
* *(Futuro Sprint 3)* `estimacion_tsp/`: Estimación de tamaños, tiempos y métricas de calidad bajo TSP.

## Reglas de Extensión (Escalabilidad sin Retrabajo):
1. Cada nuevo minijuego debe ubicarse en su propia subcarpeta con nombre semántico de alto nivel (`nombre_minijuego/`).
2. El script principal debe heredar de `MiniGameBase` (`extends MiniGameBase`).
3. Debe implementar `start_game(dificultad)` y llamar a `finish_game(exito, puntaje, estrellas)` al terminar.

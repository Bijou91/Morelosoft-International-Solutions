# Materia: Fundamentos de Ingeniería de Software (Aula 102)
**Responsable Base:** Karol Christopher Espino Galicia (Líder de Equipo)

Esta carpeta aloja los minijuegos didácticos asociados a la ingeniería de requisitos, ciclo de vida del software y metodologías ágiles/TSP.

## Minijuegos del Módulo:
* `lluvia_requerimientos/`: **Lluvia de Requerimientos** (CU-07) - El estudiante clasifica requerimientos funcionales y no funcionales en tiempo real.
* `include_extend/`: **¿Include o Extend?** (CU-08) - Práctica interactiva contra reloj para identificar relaciones UML «include» y «extend».
* `planning_poker/`: **Planning Poker** (CU-09) - Estimación ágil contra reloj de historias de usuario en puntos de historia usando la escala Fibonacci [1, 2, 3, 5, 8, 13].
* *(Futuro Sprint 2)* `casos_uso/`: Asociación interactiva de actores, precondiciones y flujos principales.
* *(Futuro Sprint 3)* `estimacion_tsp/`: Estimación de tamaños, tiempos y métricas de calidad bajo TSP.

## Reglas de Extensión (Escalabilidad sin Retrabajo):
1. Cada nuevo minijuego debe ubicarse en su propia subcarpeta con nombre semántico de alto nivel (`nombre_minijuego/`).
2. El script principal debe heredar de `MiniGameBase` (`extends MiniGameBase`).
3. Debe implementar `start_game(dificultad)` y llamar a `finish_game(exito, puntaje, estrellas)` al terminar.

## Assets Pixel Art y Estilo Visual:
* **Paleta:** *Sweetie-16 extendida* (mismos tonos de madera, pizarrón y pergamino en los 3 minijuegos + variantes Okabe-Ito para alto contraste).
* **Ubicación:** `res://assets/ing_software/` (`comun/`, `lluvia_requerimientos/`, `include_extend/`, `planning_poker/`).
* **Helper compartido:** `res://scripts/ui/PixelSkin.gd` (`class_name PixelSkin`) provee carga con caché, `StyleBoxTexture` 9-slice, barra de corazones, estrellas y fuente pixel (*Pixelify Sans*, licencia OFL). Si algún asset no existe, cada juego conserva su estilo plano de respaldo.
* **Regenerar los sprites:** ejecutar `powershell -ExecutionPolicy Bypass -File pixeling/tools/pixelart/build_all.ps1`.
* **Verificar que la lógica no se alteró:** ejecutar `powershell -ExecutionPolicy Bypass -File pixeling/tools/pixelart/verify_logic.ps1`.

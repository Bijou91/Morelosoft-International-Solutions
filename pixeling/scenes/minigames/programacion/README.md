# Materia: Introducción a la Programación (Aula 101)
**Responsable Base:** Carlos Manuel Aguirre Norato (Líder Técnico)

Esta carpeta aloja los minijuegos didácticos asociados a los contenidos curriculares de Programación de primer semestre.

## Minijuegos del Módulo:
* `roboflow/`: **RoboFlow (Control de Flujos)** - El estudiante estructura secuencias algorítmicas de comandos para guiar un robot a la meta en el tablero del laberinto.
* *(Futuro Sprint 2)* `condicionales/`: Práctica de ramificaciones lógicas if/else con semáforos o sensores.
* *(Futuro Sprint 3)* `bucles_repeticion/`: Optimización de algoritmos reduciendo instrucciones repetitivas con bucles for/while.
* *(Futuro)* `arreglos_matrices/`: Manipulación de listas e indexación matricial.

## Reglas de Extensión (Escalabilidad sin Retrabajo):
1. Cada nuevo minijuego debe ubicarse en su propia subcarpeta con nombre semántico de alto nivel (`nombre_minijuego/`).
2. El script principal debe heredar de `MiniGameBase` (`extends MiniGameBase`).
3. Debe implementar `start_game(dificultad)` y llamar a `finish_game(exito, puntaje, estrellas)` al terminar.

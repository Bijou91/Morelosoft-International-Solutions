# Materia: Lógica Computacional y Algoritmos (Aula 103)
**Responsable Base:** Omar Alejandro Martínez Martínez (Responsable de Colaboración)

Esta carpeta aloja los minijuegos didácticos asociados a lógica matemática, proposicional y razonamiento algorítmico.

## Minijuegos del Módulo:
* `derby_de_bateo/`: **Derby de Bateo** - Preguntas de lógica y algoritmos con temporizador de 10s. Opciones según dificultad (2/3/5). Sistema de vidas local. Preguntas cargadas desde JSON por dificultad.
* *(Futuro)* `tablas_verdad/`: **Tablas de Verdad y Proposiciones** - Resolución interactiva de tablas booleanas y operadores lógicos.
* *(Futuro Sprint 2)* `compuertas_logicas/`: Construcción y conexionado de circuitos con compuertas AND, OR, NOT, XOR.
* *(Futuro Sprint 3)* `arboles_decision/`: Evaluación de árboles de decisión y deducción lógica.

## Reglas de Extensión (Escalabilidad sin Retrabajo):
1. Cada nuevo minijuego debe ubicarse en su propia subcarpeta con nombre semántico de alto nivel (`nombre_minijuego/`).
2. El script principal debe heredar de `MiniGameBase` (`extends MiniGameBase`).
3. Debe implementar `start_game(dificultad)` y llamar a `finish_game(exito, puntaje, estrellas)` al terminar.
4. Los datos de preguntas/contenido deben vivir dentro de la carpeta del minijuego (ej. `data/`) para mantener aislamiento.

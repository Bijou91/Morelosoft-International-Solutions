# PixelIng - Proyecto Móvil en Godot 4 (Android)

**Equipo:** Morelosoft International Solutions  
**Líder Técnico & Arquitecto:** Carlos Manuel Aguirre Norato  
**Motor de Desarrollo:** Godot Engine 4.x (GDScript)  
**Plataforma Objetivo:** Android (Orientación Vertical / Portrait 9:16)  
**Estándar de Calidad:** ISO/IEC 29110-5-1-1 / TSP SI.01 y SI.03  

---

## Estructura del Proyecto en Godot

```text
pixeling/
├── project.godot               # Configuración del motor (resolución vertical 360x640, pixel art filter)
├── icon.svg                    # Icono de la app
├── assets/                     # Sprites pixel art y recursos
├── scripts/
│   ├── core/
│   │   ├── EventBus.gd         # Autoload: Señales globales desacopladas
│   │   ├── StateManager.gd     # Autoload: Persistencia local (user://pixeling_save.json)
│   │   └── AudioManager.gd     # Autoload: Sonidos retro 8-bit sintetizados
│   └── minigames/
│       └── MiniGameBase.gd     # Contrato arquitectónico (Clase base que TODO minijuego hereda)
└── scenes/
    ├── campus/
    │   ├── Lobby.tscn          # Navegación del campus virtual
    │   └── Lobby.gd
    ├── classroom/              # Aulas temáticas de materias
    │   ├── ClassroomBase.tscn  # Plantilla base reutilizable de aula
    │   ├── ClassroomBase.gd
    │   └── AulaProgramacion.tscn
    └── minigames/
        ├── programacion/       # Materia: Introducción a la Programación
        │   └── roboflow/       # RoboFlow: Control de Flujos (Carlos Aguirre)
        ├── ing_software/       # Materia: Fundamentos de Ing. de Software
        │   └── lluvia_requerimientos/ # Lluvia de Requerimientos (Karol Espino)
        ├── logica/             # Materia: Lógica Computacional y Algoritmos
        │   └── tablas_verdad/  # Tablas de Verdad (Omar Martínez)
        └── sistemas_operativos/# Materia: Sistemas Operativos y Linux
            └── terminal_linux/ # Terminal de Comandos Linux (Héctor Varela)
```

---

## Como Abrir y Ejecutar el Proyecto

1. Abre **Godot 4** en tu computadora.
2. Haz clic en **Importar** (Import).
3. Selecciona el archivo `project.godot` dentro de la carpeta `pixeling/` del repositorio.
4. Haz clic en **Importar y Editar** (Import & Edit).
5. Presiona **F5** (o el botón de Play en la esquina superior derecha) para ejecutar la escena principal (`Lobby.tscn`).
   * La ventana se abrirá en relación de aspecto vertical de teléfono móvil.
   * Puedes interactuar con los NPCs (estudiantes y profesores) y entrar al **Aula 101** para jugar **RoboFlow**.

---

## Exportacion a Android (.APK)

1. En Godot, ve a **Proyecto > Exportar...** (Project > Export).
2. Añade un preset de **Android**.
3. Conecta tu teléfono Android con depuración USB activada.
4. Puedes hacer clic en el botón de **Un solo clic (One-click Deploy / Icono de Android)** para instalar y probar la app directamente en tu teléfono, o hacer clic en **Exportar Proyecto** para generar el archivo `PixelIng.apk`.

---

## Guia de Desarrollo: Integracion de Minijuegos y Escalabilidad

Para garantizar escalabilidad y modularidad sin retrabajo, la carpeta `scenes/minigames/` está seccionada en las 4 materias del primer semestre con nombres semánticos de alto nivel:

* **Programación:** `scenes/minigames/programacion/roboflow/` (Carlos Aguirre) + futuros minijuegos
* **Ing. de Software:** `scenes/minigames/ing_software/lluvia_requerimientos/` (Karol Espino) + futuros minijuegos
* **Lógica Computacional:** `scenes/minigames/logica/tablas_verdad/` (Omar Martínez) + futuros minijuegos
* **Sistemas Operativos:** `scenes/minigames/sistemas_operativos/terminal_linux/` (Héctor Varela) + futuros minijuegos

### Paso 1: Heredar de `MiniGameBase`
En el script de tu minijuego (ej. `LluviaReqs.gd`):

```gdscript
extends MiniGameBase

func _ready() -> void:
    super._ready()
    cu_id = "CU-07"
    minigame_title = "Lluvia de Requerimientos"
    subject_name = "Ingeniería de Software"

func start_game(difficulty: String = "NORMAL") -> void:
    super.start_game(difficulty)
    # Inicializa tu juego aquí

func finalizar_partida() -> void:
    # Registra puntos y estrellas automáticamente en StateManager:
    finish_game(true, 300, 3, "¡Excelente clasificación!")
    get_tree().change_scene_to_file("res://scenes/campus/Lobby.tscn")
```

### Paso 2: Vincular la Escena en el Lobby
En `scenes/campus/Lobby.gd`, reemplaza la ruta vacía de tu aula por la ruta a tu escena `.tscn`:
```gdscript
btn_door_soft.pressed.connect(func(): _open_classroom("CU-07", "Aula 102", "res://scenes/minigames/ing_software/lluvia_requerimientos/LluviaReqs.tscn"))
```

## MiniGameBase - Contrato Arquitectónico para Minijuegos en Godot 4
## Todo minijuego (CU-07, CU-10, CU-13, CU-16) debe heredar de esta clase base.
## Responsable de la Arquitectura: Carlos Manuel Aguirre Norato (Líder Técnico)
class_name MiniGameBase
extends Control

signal game_finished(result: Dictionary)

@export var minigame_id: String = "minijuego"
@export var cu_id: String = "" # Retrocompatibilidad opcional
@export var minigame_title: String = "Minijuego"
@export var subject_name: String = "Materia"

var current_difficulty: String = "NORMAL" # FACIL, NORMAL, INGENIERO
var start_time_ms: int = 0

func _ready() -> void:
	start_time_ms = Time.get_ticks_msec()
	if EventBus and not EventBus.settings_changed.is_connected(_on_base_settings_changed):
		EventBus.settings_changed.connect(_on_base_settings_changed)
	
	# Aplicar el estado inicial de accesibilidad
	var high_contrast: bool = StateManager.is_high_contrast_active() if StateManager else false
	_apply_accessibility_mode(high_contrast)

func _exit_tree() -> void:
	if EventBus and EventBus.settings_changed.is_connected(_on_base_settings_changed):
		EventBus.settings_changed.disconnect(_on_base_settings_changed)

func _on_base_settings_changed(new_settings: Dictionary) -> void:
	var active: bool = new_settings.get("high_contrast", false)
	_apply_accessibility_mode(active)

## Método virtual para que cada minijuego reaccione al modo de alto contraste / daltónico.
## Por defecto, resalta todos los botones interactivos del árbol del minijuego.
func _apply_accessibility_mode(is_active: bool) -> void:
	highlight_all_buttons(self, is_active)

## Aplica recursivamente un estilo de alto contraste o restaura los botones interactivos
func highlight_all_buttons(node: Node, is_active: bool) -> void:
	if not is_instance_valid(node):
		return
	if node is Button:
		highlight_button(node as Button, is_active)
	for child in node.get_children():
		highlight_all_buttons(child, is_active)

## Resalta un botón individual con un borde nítido de alto contraste (amarillo dorado/blanco sobre fondo oscuro)
func highlight_button(btn: Button, is_active: bool, border_color: Color = Color(1.0, 0.90, 0.20, 0.95)) -> void:
	if not is_instance_valid(btn):
		return
	if is_active:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.12, 0.18, 0.95)
		sb.set_border_width_all(2)
		sb.border_color = border_color
		sb.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", sb)
		
		var sb_focus := sb.duplicate()
		sb_focus.bg_color = Color(0.16, 0.19, 0.26, 0.98)
		sb_focus.border_color = Color(1.0, 1.0, 1.0, 1.0)
		btn.add_theme_stylebox_override("focus", sb_focus)
		btn.add_theme_stylebox_override("hover", sb_focus)
		btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		btn.remove_theme_stylebox_override("normal")
		btn.remove_theme_stylebox_override("focus")
		btn.remove_theme_stylebox_override("hover")
		btn.remove_theme_color_override("font_color")

## Método virtual que cada minijuego debe sobreescribir para inicializar su lógica y dificultad
func start_game(difficulty: String = "NORMAL") -> void:
	current_difficulty = difficulty
	start_time_ms = Time.get_ticks_msec()

## Finaliza el minijuego, registra el resultado y emite la señal al gestor de estado
func finish_game(success: bool, score: int, stars: int, message: String = "") -> void:
	var time_elapsed_sec: int = int((Time.get_ticks_msec() - start_time_ms) / 1000.0)
	var active_id: String = minigame_id if minigame_id != "" else cu_id
	var result := {
		"game_id": active_id,
		"title": minigame_title,
		"success": success,
		"score": score,
		"stars": stars,
		"message": message,
		"time_elapsed": time_elapsed_sec
	}
	
	StateManager.record_minigame_result(active_id, result)
	game_finished.emit(result)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# F8 o Ctrl+W: Victoria instantánea en el minijuego actual (Modo QA / Documentación)
		if event.keycode == KEY_F8 or (event.keycode == KEY_W and event.ctrl_pressed):
			_trigger_debug_win()

## Método de depuración para forzar la victoria con 3 estrellas en el minijuego activo
func _trigger_debug_win() -> void:
	print("[DEBUG QA] Forzando victoria instantánea en: ", minigame_id)
	# Asegurar métricas altas para cálculo de 3 estrellas
	if "score" in self and get("score") == 0:
		set("score", 1000)
	if "total_score" in self and get("total_score") == 0:
		set("total_score", 1000)
	if "total_correct" in self and get("total_correct") == 0:
		set("total_correct", 10)
	if "total_answered" in self and get("total_answered") == 0:
		set("total_answered", 10)
	if "current_lives" in self and "max_lives" in self:
		if get("max_lives") == 0:
			set("max_lives", 3)
		set("current_lives", get("max_lives"))
	if "instructions" in self:
		set("instructions", [])

	if has_method("_handle_victory"):
		call("_handle_victory")
	elif has_method("handle_victory"):
		call("handle_victory")
	elif has_method("_handle_win"):
		call("_handle_win")
	elif has_method("finish_level"):
		call("finish_level")
	elif has_method("_on_all_pairs_connected"):
		call("_on_all_pairs_connected")
	elif has_method("_handle_game_over"):
		set("total_correct", 10)
		set("total_score", 1500)
		call("_handle_game_over", "¡Derby Superado con Éxito (Modo Debug QA)!")
	else:
		finish_game(true, 1000, 3, "Victoria Debug QA")

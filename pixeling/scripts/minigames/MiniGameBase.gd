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

const AULA101_HEART_FULL := preload("res://assets/ing_software/comun/hud/heart_full.png")
const AULA101_HEART_EMPTY := preload("res://assets/ing_software/comun/hud/heart_empty.png")

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
	if btn.get_meta("kenney_custom_managed", false):
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
	elif btn.get_meta("kenney_styled", false):
		style_kenney_button(btn, str(btn.get_meta("kenney_color", "neutral")), -1.0)
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
	# Ocultar modales de dificultad o tutorial previos si existen
	if has_method("_hide_all_modals"):
		call("_hide_all_modals")

	# Asegurar métricas altas para cálculo de 3 estrellas
	if "score" in self and get("score") == 0:
		set("score", 1000)
	if "total_score" in self and get("total_score") == 0:
		set("total_score", 1000)
	if "correct_answers_count" in self:
		set("correct_answers_count", 5)
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

# ==============================================================================
# ESTÁNDAR VISUAL DE INTERFAZ (KENNEY UI & FONDOS DE AULA)
# ==============================================================================

## Inyecta el fondo del aula (salon.jpg + DarkOverlay) como fondo de una pantalla o contenedor
func attach_classroom_background(target: Control, overlay_alpha: float = 0.65) -> void:
	if not is_instance_valid(target):
		return
	if target.has_node("ClassroomBg"):
		return
	if target is ColorRect:
		(target as ColorRect).color = Color(0, 0, 0, 0)
	
	var bg := TextureRect.new()
	bg.name = "ClassroomBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var path := "res://assets/lobby/salon.jpg"
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			bg.texture = res
	elif FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img and not img.is_empty():
			bg.texture = ImageTexture.create_from_image(img)
	
	var overlay := ColorRect.new()
	overlay.name = "DarkOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.04, 0.05, 0.08, overlay_alpha)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	target.add_child(bg)
	target.move_child(bg, 0)
	target.add_child(overlay)
	target.move_child(overlay, 1)

## Aplica estilos Kenney UI Pack según el color ("green", "blue", "yellow", "red", "neutral")
func style_kenney_button(btn: Button, color_type: String = "neutral", custom_h: float = 40.0) -> void:
	if not is_instance_valid(btn):
		return
	
	var base_path := "res://scenes/ui/theme/classic/btn_%s_" % color_type
	var norm_path := base_path + "normal.tres"
	var hov_path := base_path + "hover.tres"
	var press_path := base_path + "pressed.tres"
	
	if ResourceLoader.exists(norm_path) and ResourceLoader.exists(hov_path) and ResourceLoader.exists(press_path):
		btn.add_theme_stylebox_override("normal", load(norm_path))
		btn.add_theme_stylebox_override("hover", load(hov_path))
		btn.add_theme_stylebox_override("pressed", load(press_path))
		btn.add_theme_stylebox_override("focus", load(hov_path))
	
	match color_type:
		"green":
			btn.add_theme_color_override("font_color", Color(0.04, 0.22, 0.08, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.02, 0.30, 0.05, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(0.0, 0.15, 0.02, 1.0))
		"yellow":
			btn.add_theme_color_override("font_color", Color(0.24, 0.18, 0.02, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.34, 0.24, 0.02, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(0.15, 0.10, 0.0, 1.0))
		"blue":
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9, 1.0))
		"red":
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9, 1.0))
		"neutral", _:
			btn.add_theme_color_override("font_color", Color(0.18, 0.20, 0.28, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.08, 0.10, 0.18, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.0, 1.0))
	
	if custom_h > 0.0:
		btn.custom_minimum_size = Vector2(btn.custom_minimum_size.x, custom_h)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.set_meta("kenney_styled", true)
	btn.set_meta("kenney_color", color_type)

## Aplica texturas de barra de progreso del paquete Kenney Space Expansion UI
func style_kenney_progress_bar(bar: ProgressBar, fill_tint: Color = Color(1.0, 1.0, 1.0, 1.0)) -> void:
	if not is_instance_valid(bar):
		return
	var bg_path := "res://assets/interfazUI/kenney_ui-pack-space-expansion/PNG/Extra/Double/bar_shadow_square_large.png"
	var fill_path := "res://assets/interfazUI/kenney_ui-pack-space-expansion/PNG/Blue/Double/bar_square_large.png"
	if ResourceLoader.exists(bg_path):
		var sb_bg := StyleBoxTexture.new()
		sb_bg.texture = load(bg_path)
		sb_bg.texture_margin_left = 8.0
		sb_bg.texture_margin_top = 4.0
		sb_bg.texture_margin_right = 8.0
		sb_bg.texture_margin_bottom = 4.0
		sb_bg.modulate_color = Color(0.25, 0.30, 0.42, 0.90)
		bar.add_theme_stylebox_override("background", sb_bg)
	if ResourceLoader.exists(fill_path):
		var sb_fill := StyleBoxTexture.new()
		sb_fill.texture = load(fill_path)
		sb_fill.texture_margin_left = 8.0
		sb_fill.texture_margin_top = 4.0
		sb_fill.texture_margin_right = 8.0
		sb_fill.texture_margin_bottom = 4.0
		sb_fill.modulate_color = fill_tint
		bar.add_theme_stylebox_override("fill", sb_fill)

## Añade la textura de hoja de libreta de cuaderno como fondo didáctico con transparencia configurable
func attach_notebook_background(target: Control, overlay_alpha: float = 0.80) -> void:
	if not is_instance_valid(target):
		return
	var bg := TextureRect.new()
	bg.name = "NotebookBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var path := "res://assets/minigames/aula101/notebook_paper.svg"
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			bg.texture = res
	
	var overlay := ColorRect.new()
	overlay.name = "NotebookDarkOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.06, 0.08, 0.12, overlay_alpha)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	target.add_child(bg)
	target.move_child(bg, 0)
	target.add_child(overlay)
	target.move_child(overlay, 1)

## Aplica estilos Kenney UI Pack a un panel contenedor ("screws", "inner", "glass", "rect")
func style_kenney_panel(panel: PanelContainer, panel_type: String = "screws") -> void:
	if not is_instance_valid(panel):
		return
	var path := ""
	match panel_type:
		"screws":
			path = "res://scenes/ui/theme/classic/panel_screws.tres"
		"inner":
			path = "res://scenes/ui/theme/classic/panel_inner_plate.tres"
		"glass":
			path = "res://scenes/ui/theme/classic/panel_glass.tres"
		"rect", _:
			path = "res://scenes/ui/theme/classic/panel_rect.tres"
	if ResourceLoader.exists(path):
		panel.add_theme_stylebox_override("panel", load(path))

const MiniGameFlowTemplateClass = preload("res://scripts/minigames/MiniGameFlowTemplate.gd")

## Crea y configura la plantilla universal de flujo (Instrucciones -> Dificultad -> Pausa)
func create_flow_template(config: Dictionary) -> Control:
	var template = MiniGameFlowTemplateClass.new()
	add_child(template)
	template.setup(config)
	return template

## Inspector reactivo que ajusta automáticamente el font_size de un Label o Button al rectángulo fijo de su host
class _DynamicTextFitter extends Node:
	var target_ctrl: Control
	var size_host: Control
	var max_font_size: int = 12
	var min_font_size: int = 7
	var pad_x: float = 0.0
	var pad_y: float = 0.0
	var fallback_size: Vector2 = Vector2(300.0, 36.0)
	var allow_wrap: bool = true
	var _last_sig: String = ""

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		if is_instance_valid(size_host):
			if not size_host.resized.is_connected(_on_trigger):
				size_host.resized.connect(_on_trigger)
		if is_instance_valid(target_ctrl):
			if not target_ctrl.visibility_changed.is_connected(_on_trigger):
				target_ctrl.visibility_changed.connect(_on_trigger)
		check_and_fit(true)

	func _on_trigger() -> void:
		check_and_fit(true)

	func _process(_delta: float) -> void:
		check_and_fit(false)

	func check_and_fit(force: bool = false) -> void:
		if not is_instance_valid(target_ctrl) or not is_instance_valid(size_host):
			return
		var txt := ""
		if target_ctrl is Label:
			txt = (target_ctrl as Label).text
		elif target_ctrl is Button:
			txt = (target_ctrl as Button).text
		else:
			return
		var w := size_host.size.x if size_host.size.x > 4.0 else maxf(fallback_size.x, size_host.custom_minimum_size.x)
		var h := size_host.size.y if size_host.size.y > 4.0 else maxf(fallback_size.y, size_host.custom_minimum_size.y)
		var sig := "%s|%d|%d" % [txt, roundi(w), roundi(h)]
		if not force and sig == _last_sig:
			return
		_last_sig = sig
		MiniGameBase.apply_text_auto_fit(target_ctrl, Vector2(w, h), max_font_size, min_font_size, pad_x, pad_y, allow_wrap)

## Calcula y aplica el mayor tamaño de fuente [min_font_size..max_font_size] que cabe dentro de box_size
static func apply_text_auto_fit(ctrl: Control, box_size: Vector2, max_font_size: int = 12, min_font_size: int = 7, pad_x: float = 0.0, pad_y: float = 0.0, allow_wrap: bool = true) -> int:
	if not is_instance_valid(ctrl):
		return min_font_size
	var txt := ""
	var align := HORIZONTAL_ALIGNMENT_LEFT
	var line_spacing := 0.0
	if ctrl is Label:
		var lbl := ctrl as Label
		txt = lbl.text
		align = lbl.horizontal_alignment
		line_spacing = maxf(0.0, float(lbl.get_theme_constant("line_spacing")))
	elif ctrl is Button:
		var btn := ctrl as Button
		txt = btn.text
		align = btn.alignment
		var sb: StyleBox = btn.get_theme_stylebox("normal")
		if sb != null:
			pad_x += (sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)) * 0.5
			pad_y += (sb.get_margin(SIDE_TOP) + sb.get_margin(SIDE_BOTTOM)) * 0.5
	else:
		return min_font_size

	var hi := maxi(min_font_size, max_font_size)
	var lo := mini(min_font_size, hi)
	if txt.strip_edges().is_empty():
		ctrl.add_theme_font_size_override("font_size", hi)
		return hi

	var avail_w := box_size.x - pad_x * 2.0 - 4.0
	var avail_h := box_size.y - pad_y * 2.0 - 2.0
	if avail_w <= 6.0 or avail_h <= 6.0:
		ctrl.add_theme_font_size_override("font_size", lo)
		return lo

	var font: Font = ctrl.get_theme_font("font")
	if font == null:
		ctrl.add_theme_font_size_override("font_size", hi)
		return hi

	var brk_flags := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
	var chosen := lo
	for fs in range(hi, lo - 1, -1):
		var measured: Vector2
		if allow_wrap:
			measured = font.get_multiline_string_size(txt, align, avail_w, fs, -1, brk_flags)
			var line_h := maxf(1.0, font.get_height(fs))
			var est_lines := maxi(1, roundi(measured.y / line_h))
			measured.y += float(est_lines - 1) * line_spacing
		else:
			measured = font.get_string_size(txt, align, -1.0, fs)
		if measured.x <= avail_w + 0.5 and measured.y <= avail_h + 0.5:
			chosen = fs
			break

	ctrl.add_theme_font_size_override("font_size", chosen)
	return chosen

## Ajusta de inmediato un Control bloqueado con lock_dynamic_label_box o lock_dynamic_button_box
func fit_control_text_now(ctrl: Control) -> void:
	if not is_instance_valid(ctrl) or not ctrl.has_meta("_fixed_text_fitter"):
		return
	var fitter = ctrl.get_meta("_fixed_text_fitter")
	if is_instance_valid(fitter) and fitter is _DynamicTextFitter:
		(fitter as _DynamicTextFitter).check_and_fit(true)

## Encierra un Label en un Control host de tamaño fijo (sin propagar altura/anchura del texto al layout)
## y escala dinámicamente el texto para adaptarse al contenedor fijo.
func lock_dynamic_label_box(
	label: Label,
	outer_panel: Control = null,
	fixed_height: float = -1.0,
	max_font_size: int = 12,
	min_font_size: int = 7,
	inner_pad_x: float = 0.0,
	inner_pad_y: float = 0.0,
	allow_wrap: bool = true,
	center_vertical: bool = true,
	compact_panel_pad_y: float = -1.0
) -> Control:
	if not is_instance_valid(label):
		return null
	var existing_parent := label.get_parent()
	if existing_parent == null:
		return null

	# Opcionalmente compactar márgenes verticales del PanelContainer para aprovechar la altura fija
	if is_instance_valid(outer_panel) and outer_panel is PanelContainer and compact_panel_pad_y >= 0.0:
		var panel_c := outer_panel as PanelContainer
		var orig_sb := panel_c.get_theme_stylebox("panel")
		if orig_sb != null:
			var cloned_sb := orig_sb.duplicate()
			cloned_sb.content_margin_top = compact_panel_pad_y
			cloned_sb.content_margin_bottom = compact_panel_pad_y
			panel_c.add_theme_stylebox_override("panel", cloned_sb)

	var chrome_x := 0.0
	var chrome_y := 0.0
	if is_instance_valid(outer_panel):
		var cur: Node = existing_parent
		while cur != null:
			if cur is PanelContainer:
				var sb := (cur as PanelContainer).get_theme_stylebox("panel")
				if sb != null:
					chrome_x += sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)
					chrome_y += sb.get_margin(SIDE_TOP) + sb.get_margin(SIDE_BOTTOM)
			elif cur is MarginContainer:
				var mc := cur as MarginContainer
				chrome_x += float(mc.get_theme_constant("margin_left") + mc.get_theme_constant("margin_right"))
				chrome_y += float(mc.get_theme_constant("margin_top") + mc.get_theme_constant("margin_bottom"))
			if cur == outer_panel:
				break
			cur = cur.get_parent()

	var target_panel_h := fixed_height
	if target_panel_h <= 0.0:
		if is_instance_valid(outer_panel) and outer_panel.custom_minimum_size.y > 0.0:
			target_panel_h = outer_panel.custom_minimum_size.y
		elif label.custom_minimum_size.y > 0.0:
			target_panel_h = label.custom_minimum_size.y + chrome_y
		else:
			target_panel_h = 38.0 + chrome_y

	if is_instance_valid(outer_panel):
		outer_panel.custom_minimum_size.y = target_panel_h
		outer_panel.size_flags_vertical &= ~Control.SIZE_EXPAND

	var inner_h := maxf(10.0, target_panel_h - chrome_y)
	var min_w := maxf(0.0, label.custom_minimum_size.x)
	if is_instance_valid(outer_panel) and outer_panel.custom_minimum_size.x > 0.0 and min_w <= 0.0:
		min_w = maxf(0.0, outer_panel.custom_minimum_size.x - chrome_x)

	var host: Control
	if existing_parent.has_meta("_is_fixed_text_host"):
		host = existing_parent as Control
	else:
		host = Control.new()
		host.name = label.name + "_FixedBox"
		host.set_meta("_is_fixed_text_host", true)
		host.clip_contents = true
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE if label.mouse_filter == Control.MOUSE_FILTER_IGNORE else Control.MOUSE_FILTER_PASS
		if existing_parent is PanelContainer or existing_parent is MarginContainer:
			host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			host.size_flags_vertical = Control.SIZE_EXPAND_FILL
		elif existing_parent is Container:
			host.size_flags_horizontal = label.size_flags_horizontal
			host.size_flags_vertical = label.size_flags_vertical & ~Control.SIZE_EXPAND
		else:
			host.anchor_left = label.anchor_left
			host.anchor_top = label.anchor_top
			host.anchor_right = label.anchor_right
			host.anchor_bottom = label.anchor_bottom
			host.offset_left = label.offset_left
			host.offset_top = label.offset_top
			host.offset_right = label.offset_right
			host.offset_bottom = label.offset_bottom
		var idx := label.get_index()
		existing_parent.add_child(host)
		existing_parent.move_child(host, idx)
		label.reparent(host, false)

	host.custom_minimum_size = Vector2(min_w, inner_h)
	label.custom_minimum_size = Vector2.ZERO
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = inner_pad_x
	label.offset_top = inner_pad_y
	label.offset_right = -inner_pad_x
	label.offset_bottom = -inner_pad_y
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if allow_wrap else TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if center_vertical:
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var est_w := min_w if min_w > 20.0 else (maxf(120.0, outer_panel.size.x - chrome_x) if is_instance_valid(outer_panel) and outer_panel.size.x > 20.0 else 310.0)
	var fitter: _DynamicTextFitter = null
	if label.has_meta("_fixed_text_fitter"):
		fitter = label.get_meta("_fixed_text_fitter") as _DynamicTextFitter
	if fitter == null:
		fitter = _DynamicTextFitter.new()
		fitter.name = "_TextFitter"
		host.add_child(fitter)
		label.set_meta("_fixed_text_fitter", fitter)
	fitter.target_ctrl = label
	fitter.size_host = host
	fitter.max_font_size = max_font_size
	fitter.min_font_size = min_font_size
	fitter.pad_x = inner_pad_x
	fitter.pad_y = inner_pad_y
	fitter.fallback_size = Vector2(est_w, inner_h)
	fitter.allow_wrap = allow_wrap
	fitter.check_and_fit(true)
	return host

## Encierra un Button de texto dinámico en un host fijo para evitar que el texto largo agrande el botón
func lock_dynamic_button_box(
	btn: Button,
	fixed_height: float = 40.0,
	max_font_size: int = 11,
	min_font_size: int = 7,
	allow_wrap: bool = true,
	est_width: float = 160.0
) -> Control:
	if not is_instance_valid(btn):
		return null
	var existing_parent := btn.get_parent()
	if existing_parent == null:
		return null

	var min_w := maxf(0.0, btn.custom_minimum_size.x)
	var host: Control
	if existing_parent.has_meta("_is_fixed_text_host"):
		host = existing_parent as Control
	else:
		host = Control.new()
		host.name = btn.name + "_FixedBox"
		host.set_meta("_is_fixed_text_host", true)
		host.clip_contents = true
		host.mouse_filter = Control.MOUSE_FILTER_PASS
		host.size_flags_horizontal = btn.size_flags_horizontal
		host.size_flags_vertical = btn.size_flags_vertical & ~Control.SIZE_EXPAND
		var idx := btn.get_index()
		existing_parent.add_child(host)
		existing_parent.move_child(host, idx)
		btn.reparent(host, false)

	host.custom_minimum_size = Vector2(min_w, fixed_height)
	btn.custom_minimum_size = Vector2.ZERO
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.offset_left = 0.0
	btn.offset_top = 0.0
	btn.offset_right = 0.0
	btn.offset_bottom = 0.0
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if allow_wrap else TextServer.AUTOWRAP_OFF
	btn.clip_text = true
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	var fallback_w := min_w if min_w > 20.0 else est_width
	var fitter: _DynamicTextFitter = null
	if btn.has_meta("_fixed_text_fitter"):
		fitter = btn.get_meta("_fixed_text_fitter") as _DynamicTextFitter
	if fitter == null:
		fitter = _DynamicTextFitter.new()
		fitter.name = "_TextFitter"
		host.add_child(fitter)
		btn.set_meta("_fixed_text_fitter", fitter)
	fitter.target_ctrl = btn
	fitter.size_host = host
	fitter.max_font_size = max_font_size
	fitter.min_font_size = min_font_size
	fitter.pad_x = 0.0
	fitter.pad_y = 0.0
	fitter.fallback_size = Vector2(fallback_w, fixed_height)
	fitter.allow_wrap = allow_wrap
	fitter.check_and_fit(true)
	return host

## Fija ancho mínimo estable y desactiva saltos/expansión en contadores numéricos de HUD
func stabilize_hud_label(label: Label, min_width: float = 48.0, fixed_height: float = 0.0) -> void:
	if not is_instance_valid(label):
		return
	label.custom_minimum_size.x = maxf(label.custom_minimum_size.x, min_width)
	if fixed_height > 0.0:
		label.custom_minimum_size.y = fixed_height
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

## Serializa el contenedor TopHUD del Aula 101 (Programación) con margen uniforme Kenney UI
func style_aula101_hud_panel(panel: PanelContainer) -> void:
	if not is_instance_valid(panel):
		return
	var base_sb := load("res://scenes/ui/theme/classic/panel_inner_plate.tres") as StyleBoxTexture
	if base_sb:
		var sb := base_sb.duplicate() as StyleBoxTexture
		sb.content_margin_left = 8.0
		sb.content_margin_right = 8.0
		sb.content_margin_top = 4.0
		sb.content_margin_bottom = 4.0
		panel.add_theme_stylebox_override("panel", sb)
	else:
		style_kenney_panel(panel, "inner")
	panel.custom_minimum_size.y = 40.0

## Estandariza el botón de pausa en todos los minijuegos de Aula 101 ("||" Kenney neutral 34x30)
func style_aula101_pause_button(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	btn.text = "||"
	btn.custom_minimum_size = Vector2(34.0, 30.0)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	style_kenney_button(btn, "neutral", 30.0)
	for state_name in ["normal", "hover", "pressed"]:
		var base_sb := btn.get_theme_stylebox(state_name) as StyleBoxTexture
		if base_sb:
			var sb := base_sb.duplicate() as StyleBoxTexture
			sb.content_margin_left = 8.0
			sb.content_margin_right = 8.0
			sb.content_margin_top = 4.0
			sb.content_margin_bottom = 6.0
			btn.add_theme_stylebox_override(state_name, sb)
			if state_name == "hover":
				btn.add_theme_stylebox_override("focus", sb)
	btn.add_theme_font_size_override("font_size", 11)

## Construye la barra unificada de corazones pixel-art (llenos + vacíos) para Aula 101
func create_aula101_hearts_bar(initial_lives: int = 3, max_lives_val: int = 3, icon_size: float = 14.0) -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.name = "HeartsBar"
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_constant_override("separation", 2)
	update_aula101_hearts_bar(bar, initial_lives, max_lives_val, null, icon_size)
	return bar

## Actualiza los sprites de corazones pixel-art y mantiene un ancho fijo estable
func update_aula101_hearts_bar(bar: HBoxContainer, current_lives: int, max_lives_val: int, fallback_label: Label = null, icon_size: float = 14.0) -> void:
	var total: int = maxi(1, max_lives_val)
	var alive: int = clampi(current_lives, 0, total)
	if is_instance_valid(fallback_label):
		fallback_label.text = "Vidas: %d/%d" % [alive, total]
		fallback_label.visible = false
	if not is_instance_valid(bar):
		return
	bar.custom_minimum_size = Vector2(float(total) * icon_size + float(maxi(0, total - 1)) * 2.0, icon_size)
	if bar.get_child_count() != total:
		for ch in bar.get_children():
			bar.remove_child(ch)
			ch.queue_free()
		for i in range(total):
			var icon := TextureRect.new()
			icon.name = "Heart_%d" % i
			icon.custom_minimum_size = Vector2(icon_size, icon_size)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			bar.add_child(icon)
	for i in range(total):
		var heart := bar.get_child(i) as TextureRect
		if is_instance_valid(heart):
			heart.texture = AULA101_HEART_FULL if i < alive else AULA101_HEART_EMPTY

## Envuelve un TopHUD HBoxContainer existente en una tarjeta estándar Kenney de Aula 101
func wrap_hbox_in_aula101_hud_panel(hbox: HBoxContainer, panel_name: String = "TopHUDPanel") -> PanelContainer:
	if not is_instance_valid(hbox):
		return null
	var parent := hbox.get_parent()
	if parent is PanelContainer:
		style_aula101_hud_panel(parent as PanelContainer)
		return parent as PanelContainer
	if not is_instance_valid(parent):
		return null
	var idx: int = hbox.get_index()
	var panel := PanelContainer.new()
	panel.name = panel_name
	style_aula101_hud_panel(panel)
	parent.add_child(panel)
	parent.move_child(panel, idx)
	parent.remove_child(hbox)
	hbox.add_theme_constant_override("separation", 6)
	hbox.custom_minimum_size.y = 30.0
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)
	return panel



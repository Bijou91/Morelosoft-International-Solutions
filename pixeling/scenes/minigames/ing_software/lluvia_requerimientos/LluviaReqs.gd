## LluviaReqs.gd — Minijuego CU-07: Lluvia de Requerimientos
## El jugador atrapa los requerimientos funcionales y esquiva los no funcionales.
## Cumple estrictamente con el Caso de Uso CU-07 y el Diagrama de Secuencia (TSP / ISO/IEC 29110)
## Responsable: Karol Christopher Espino Galicia
extends MiniGameBase

# ══════════════════════════════════════════════════════════════════════════════
# CONSTANTES DE DISEÑO
# ══════════════════════════════════════════════════════════════════════════════

const CART_WIDTH: float = 90.0
const CART_HEIGHT: float = 40.0
const REQ_WIDTH: float = 105.0
const REQ_HEIGHT: float = 55.0
const PLAYER_SPEED: float = 200.0
const ASSETS_DIR: String = "res://assets/ing_software/lluvia_requerimientos/"

## Banco de Requerimientos Funcionales (el jugador DEBE atrapar estos) ── 20 ítems
const FUNCTIONAL_REQS = [
	"Registrar\nusuarios",
	"Iniciar\nsesión",
	"Generar\nreportes PDF",
	"Eliminar\ncuentas",
	"Enviar\nnotificaciones",
	"Buscar\nproductos",
	"Calcular\ntotal carrito",
	"Subir\narchivos",
	"Filtrar\nresultados",
	"Cambiar\ncontraseña",
	"Registrar\ncompras",
	"Agregar\nal carrito",
	"Editar\nperfil",
	"Generar\nestadísticas",
	"Confirmar\npedidos",
	"Calificar\nproductos",
	"Exportar\ndatos CSV",
	"Recuperar\ncontraseña",
	"Mostrar\ncatálogo",
	"Gestionar\ninventario",
]

## Banco de Requerimientos NO Funcionales (el jugador DEBE esquivar estos) ── 20 ítems
const NON_FUNCTIONAL_REQS = [
	"Respuesta\n< 2 segundos",
	"Disponibilidad\n99.9%",
	"10K usuarios\nconcurrentes",
	"Cifrado\nAES-256",
	"Compatible\nnavegadores",
	"Carga máx\n3 segundos",
	"Cumplir\nISO 27001",
	"Accesible\nWCAG 2.1",
	"Backup\ncada 24h",
	"Documentación\nal 80%",
	"Uptime\nmínimo 99%",
	"App peso\n< 50 MB",
	"Soporte\n3 idiomas",
	"Android 10\no superior",
	"Latencia\n< 200ms",
	"Uso RAM\n< 512 MB",
	"Cobertura\ntests 70%",
	"Escalar a\n100K registros",
	"Cumplir\nLFPDPPP",
	"Diseño\nresponsive",
]

# ══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN DE DIFICULTAD (se asignan en _configure_difficulty)
# ══════════════════════════════════════════════════════════════════════════════

var max_lives: int = 5
var current_lives: int = 5
var game_duration: float = 75.0
var spawn_interval_start: float = 2.0
var spawn_interval_end: float = 1.0
var fall_speed_start: float = 120.0
var fall_speed_end: float = 180.0
var functional_ratio: float = 0.50
var difficulty_multiplier: int = 2

# ══════════════════════════════════════════════════════════════════════════════
# ESTADO DEL JUEGO
# ══════════════════════════════════════════════════════════════════════════════

var score: int = 0
var is_paused: bool = false
var is_game_active: bool = false
var time_remaining: float = 0.0
var spawn_timer: float = 0.0
var active_requirements: Array = []
var move_direction: int = 0 # -1 izquierda, 0 quieto, 1 derecha
var selected_difficulty: String = "NORMAL"

# ══════════════════════════════════════════════════════════════════════════════
# REFERENCIAS UI (asignadas en _build_ui)
# ══════════════════════════════════════════════════════════════════════════════

var vp_size: Vector2
var game_area_height: float

# HUD
var lives_label: Label
var score_label: Label
var timer_bar: ProgressBar

# Área de juego
var game_area: Control
var player_cart: PanelContainer
var cloud_panel: PanelContainer

# Overlays
var difficulty_overlay: ColorRect
var instructions_overlay: ColorRect
var pause_overlay: ColorRect
var game_over_overlay: ColorRect
var victory_overlay: ColorRect

# Labels de overlays (necesitan actualización dinámica)
var instr_difficulty_label: Label
var final_score_label: Label
var victory_score_label: Label
var stars_label: Label

# Nodos puramente visuales (sprites pixel art, no intervienen en la lógica)
var hearts_bar: HBoxContainer
var time_label: Label
var victory_stars_row: HBoxContainer
var dev_sprite: TextureRect
var dev_frames: Array[Texture2D] = []
var dev_anim_clock: float = 0.0

# ══════════════════════════════════════════════════════════════════════════════
# CICLO DE VIDA
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	super._ready()
	minigame_id = "lluvia_requerimientos"
	cu_id = "CU-07"
	minigame_title = "Lluvia de Requerimientos"
	subject_name = "Ingeniería de Software"

	vp_size = get_viewport_rect().size
	_build_ui()
	_show_difficulty_selector()

func _apply_accessibility_mode(is_active: bool) -> void:
	super._apply_accessibility_mode(is_active)
	for req_node in active_requirements:
		if is_instance_valid(req_node) and req_node is PanelContainer:
			var is_func: bool = req_node.get_meta("is_functional", false)
			req_node.add_theme_stylebox_override("panel", _make_req_stylebox(is_func, is_active))

func _process(delta: float) -> void:
	if not is_game_active or is_paused:
		return

	# ── 1. Temporizador ──
	time_remaining -= delta
	_update_timer_bar()
	if time_remaining <= 0.0:
		_handle_victory()
		return

	# ── 2. Spawn de requerimientos ──
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_requirement()
		spawn_timer = _get_current_spawn_interval()

	# ── 3. Movimiento del jugador (botones + teclado) ──
	var dir: int = move_direction
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir = -1
	elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir = 1
	player_cart.position.x += dir * PLAYER_SPEED * delta
	player_cart.position.x = clampf(player_cart.position.x, 0.0, game_area.size.x - CART_WIDTH)

	# ── 4. Actualizar requerimientos (caída + colisiones) ──
	_update_requirements(delta)


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if is_game_active and not is_paused:
				_toggle_pause()
			elif is_paused:
				_toggle_pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_game_active and not is_paused:
			_toggle_pause()
		elif not is_game_active:
			_on_back_pressed()

# ══════════════════════════════════════════════════════════════════════════════
# CONSTRUCCIÓN DE UI (toda la interfaz se genera programáticamente)
# ══════════════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	# ── Fondo "Tormenta en la oficina" (con respaldo de color sólido) ──
	var bg := ColorRect.new()
	bg.color = PixelSkin.C_INK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var bg_tex := PixelSkin.full_rect_background(ASSETS_DIR + "bg_storm_city.png")
	if bg_tex != null:
		add_child(bg_tex)

	# Franja de banqueta en la base (detrás de los controles)
	var ground_t := PixelSkin.tex(ASSETS_DIR + "ground_tiles.png")
	if ground_t != null:
		var ground := TextureRect.new()
		ground.texture = ground_t
		ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ground.stretch_mode = TextureRect.STRETCH_TILE
		ground.position = Vector2(0, vp_size.y - 68)
		ground.size = Vector2(vp_size.x, 68)
		add_child(ground)

	# ── Top HUD ──
	_build_top_hud()

	# ── Barra de tiempo ──
	_build_timer_bar()

	# ── Área de juego ──
	game_area_height = vp_size.y - 56.0 - 55.0
	_build_game_area()

	# ── Controles inferiores ──
	_build_controls_hud()

	# ── Overlays (orden de z-index: el último es el de arriba) ──
	_build_overlay_victory()
	_build_overlay_game_over()
	_build_overlay_pause()
	_build_overlay_instructions()
	_build_overlay_difficulty()


func _build_top_hud() -> void:
	var hud_bg := PanelContainer.new()
	hud_bg.position = Vector2(4, 3)
	hud_bg.size = Vector2(vp_size.x - 8, 36)
	var hud_sb := PixelSkin.dark_panel(4)
	if hud_sb != null:
		hud_bg.add_theme_stylebox_override("panel", hud_sb)
	else:
		hud_bg.add_theme_stylebox_override("panel", _make_stylebox(Color(0.10, 0.12, 0.18, 0.9), 4, 2, Color(0.3, 0.35, 0.45)))
	add_child(hud_bg)

	var hud := HBoxContainer.new()
	hud.add_theme_constant_override("separation", 6)
	hud_bg.add_child(hud)

	var btn_back := Button.new()
	btn_back.text = "←"
	btn_back.icon = PixelSkin.common("hud/icon_back.png")
	if btn_back.icon != null:
		btn_back.text = ""
		btn_back.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_back.custom_minimum_size = Vector2(34, 26)
	PixelSkin.skin_button(btn_back, PixelSkin.C_SLATE)
	btn_back.pressed.connect(_on_back_pressed)
	hud.add_child(btn_back)

	# Vidas (barra de corazones pixel + label existente como respaldo/lectura)
	hearts_bar = PixelSkin.make_hearts_bar()
	hud.add_child(hearts_bar)

	lives_label = Label.new()
	lives_label.text = "VIDAS: 5"
	lives_label.add_theme_font_size_override("font_size", 11)
	PixelSkin.style_label(lives_label, PixelSkin.C_WHITE)
	hud.add_child(lives_label)
	if PixelSkin.set_hearts(hearts_bar, current_lives, max_lives):
		lives_label.visible = false

	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(spacer1)

	# Reloj + tiempo restante (solo lectura de time_remaining)
	var hg := PixelSkin.common("hud/hourglass.png")
	if hg != null:
		hud.add_child(PixelSkin.icon(hg))
	time_label = Label.new()
	time_label.text = "01:15"
	time_label.add_theme_font_size_override("font_size", 11)
	PixelSkin.style_label(time_label, PixelSkin.C_WHITE)
	hud.add_child(time_label)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(spacer2)

	# Puntos (moneda pixel + label existente)
	var coin_tex := PixelSkin.common("hud/coin.png")
	if coin_tex != null:
		hud.add_child(PixelSkin.icon(coin_tex))
	score_label = Label.new()
	score_label.text = "0"
	score_label.add_theme_font_size_override("font_size", 12)
	PixelSkin.style_label(score_label, PixelSkin.C_YELLOW)
	hud.add_child(score_label)


func _build_timer_bar() -> void:
	timer_bar = ProgressBar.new()
	timer_bar.position = Vector2(8, 42)
	timer_bar.size = Vector2(vp_size.x - 16, 10)
	timer_bar.max_value = 100.0
	timer_bar.value = 100.0
	timer_bar.show_percentage = false
	var bar_bg := PixelSkin.bar_background()
	if bar_bg != null:
		timer_bar.add_theme_stylebox_override("background", bar_bg)
		timer_bar.add_theme_stylebox_override("fill", PixelSkin.bar_fill(PixelSkin.C_GREEN))
	else:
		timer_bar.add_theme_stylebox_override("fill", _make_stylebox(Color(0.22, 0.65, 0.30), 3))
		timer_bar.add_theme_stylebox_override("background", _make_stylebox(Color(0.35, 0.28, 0.18), 3))
	add_child(timer_bar)


func _build_game_area() -> void:
	game_area = Control.new()
	game_area.position = Vector2(0, 56)
	game_area.size = Vector2(vp_size.x, game_area_height)
	game_area.clip_contents = true
	add_child(game_area)

	# Lluvia decorativa (CPUParticles2D ligera, sin colisiones)
	var drop_tex := PixelSkin.tex(ASSETS_DIR + "rain_drop.png")
	if drop_tex != null:
		var rain := CPUParticles2D.new()
		rain.position = Vector2(vp_size.x * 0.55, -10)
		rain.amount = 28
		rain.lifetime = 1.6
		rain.preprocess = 1.0
		rain.texture = drop_tex
		rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		rain.emission_rect_extents = Vector2(vp_size.x * 0.65, 4)
		rain.direction = Vector2(-0.25, 1.0).normalized()
		rain.spread = 4.0
		rain.gravity = Vector2.ZERO
		rain.initial_velocity_min = 340.0
		rain.initial_velocity_max = 420.0
		rain.color = Color(1, 1, 1, 0.55)
		game_area.add_child(rain)

	# Franja de nubes pixel (reemplaza visualmente el bloque "~ NUBES ~")
	cloud_panel = PanelContainer.new()
	cloud_panel.position = Vector2(0, 0)
	cloud_panel.custom_minimum_size = Vector2(vp_size.x, 38)
	var cloud_tex := PixelSkin.tex(ASSETS_DIR + "clouds_strip.png")
	if cloud_tex != null:
		cloud_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var clouds_rect := TextureRect.new()
		clouds_rect.texture = cloud_tex
		clouds_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clouds_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		clouds_rect.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		clouds_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		clouds_rect.stretch_mode = TextureRect.STRETCH_TILE
		clouds_rect.custom_minimum_size = Vector2(vp_size.x, 36)
		cloud_panel.add_child(clouds_rect)
	else:
		cloud_panel.position = Vector2(vp_size.x / 2.0 - 100, 2)
		cloud_panel.custom_minimum_size = Vector2(200, 38)
		cloud_panel.add_theme_stylebox_override("panel", _make_stylebox(Color(0.78, 0.82, 0.88, 0.85), 16))
		var cloud_lbl := Label.new()
		cloud_lbl.text = "~ ~ ~ NUBES ~ ~ ~"
		cloud_lbl.add_theme_font_size_override("font_size", 12)
		cloud_lbl.add_theme_color_override("font_color", Color(0.55, 0.62, 0.70))
		cloud_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cloud_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cloud_panel.add_child(cloud_lbl)
	game_area.add_child(cloud_panel)

	# Caja "BACKLOG" + desarrollador (el nodo player_cart conserva CART_WIDTH x CART_HEIGHT exactos)
	player_cart = PanelContainer.new()
	player_cart.position = Vector2(vp_size.x / 2.0 - CART_WIDTH / 2.0, game_area_height - CART_HEIGHT - 28)
	player_cart.custom_minimum_size = Vector2(CART_WIDTH, CART_HEIGHT)
	var crate_tex := PixelSkin.tex(ASSETS_DIR + "backlog_crate.png")
	if crate_tex != null:
		var crate_sb := StyleBoxTexture.new()
		crate_sb.texture = crate_tex
		player_cart.add_theme_stylebox_override("panel", crate_sb)
		# Desarrollador chibi debajo de la caja (hijo visual fuera de la hitbox; las colisiones
		# usan Rect2(player_cart.position, Vector2(CART_WIDTH, CART_HEIGHT)), por lo que no las altera)
		dev_frames.clear()
		for i in range(4):
			var ft := PixelSkin.tex(ASSETS_DIR + "dev_carry_%d.png" % i)
			if ft != null:
				dev_frames.append(ft)
		if not dev_frames.is_empty():
			var holder := Node2D.new()
			holder.position = Vector2(CART_WIDTH / 2.0 - 20.0, CART_HEIGHT - 4.0)
			dev_sprite = PixelSkin.icon(dev_frames[0], Vector2(40, 32))
			holder.add_child(dev_sprite)
			player_cart.add_child(holder)
	else:
		var cart_style := _make_stylebox(Color(0.40, 0.26, 0.13), 5, 2, Color(0.28, 0.18, 0.08))
		player_cart.add_theme_stylebox_override("panel", cart_style)
		var cart_lbl := Label.new()
		cart_lbl.text = "[ VAGONETA ]"
		cart_lbl.add_theme_font_size_override("font_size", 11)
		cart_lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.75))
		cart_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cart_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		player_cart.add_child(cart_lbl)
	game_area.add_child(player_cart)


func _build_controls_hud() -> void:
	var controls := HBoxContainer.new()
	controls.position = Vector2(8, vp_size.y - 50)
	controls.size = Vector2(vp_size.x - 16, 44)
	controls.add_theme_constant_override("separation", 8)
	add_child(controls)

	var btn_left := Button.new()
	btn_left.text = "◀"
	btn_left.add_theme_font_size_override("font_size", 16)
	btn_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_left.custom_minimum_size = Vector2(0, 42)
	PixelSkin.skin_button(btn_left, PixelSkin.C_NAVY)
	btn_left.button_down.connect(func(): move_direction = -1)
	btn_left.button_up.connect(func():
		if move_direction == -1: move_direction = 0)
	controls.add_child(btn_left)

	var btn_pause := Button.new()
	btn_pause.text = "⏸"
	btn_pause.icon = PixelSkin.common("hud/icon_pause.png")
	if btn_pause.icon != null:
		btn_pause.text = ""
		btn_pause.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_pause.custom_minimum_size = Vector2(44, 42)
	PixelSkin.skin_button(btn_pause, PixelSkin.C_SLATE)
	btn_pause.pressed.connect(_toggle_pause)
	controls.add_child(btn_pause)

	var btn_right := Button.new()
	btn_right.text = "▶"
	btn_right.add_theme_font_size_override("font_size", 16)
	btn_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_right.custom_minimum_size = Vector2(0, 42)
	PixelSkin.skin_button(btn_right, PixelSkin.C_NAVY)
	btn_right.button_down.connect(func(): move_direction = 1)
	btn_right.button_up.connect(func():
		if move_direction == 1: move_direction = 0)
	controls.add_child(btn_right)


## Crea un overlay genérico: fondo semitransparente + VBoxContainer centrado.
## Devuelve [overlay_rect, vbox_container].
func _create_overlay(bg_color: Color = Color(0, 0, 0, 0.75)) -> Array:
	var overlay := ColorRect.new()
	overlay.color = bg_color
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 0)
	var psb := PixelSkin.dark_panel()
	if psb != null:
		panel.add_theme_stylebox_override("panel", psb)
	else:
		panel.add_theme_stylebox_override("panel", _make_stylebox(Color(0.12, 0.13, 0.18, 0.95), 12, 2, Color(0.4, 0.45, 0.55)))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	add_child(overlay)
	return [overlay, vbox]


func _build_overlay_difficulty() -> void:
	var parts: Array = _create_overlay(Color(0, 0, 0, 0.85))
	difficulty_overlay = parts[0]
	var vbox: VBoxContainer = parts[1]

	var title := Label.new()
	title.text = "Lluvia de Requerimientos"
	title.add_theme_font_size_override("font_size", 15)
	PixelSkin.style_label(title, PixelSkin.C_YELLOW)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Atrapa los requerimientos funcionales\ny esquiva los no funcionales"
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var lbl_diff := Label.new()
	lbl_diff.text = "Selecciona la dificultad:"
	lbl_diff.add_theme_font_size_override("font_size", 10)
	PixelSkin.style_label(lbl_diff, PixelSkin.C_WHITE)
	lbl_diff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_diff)

	var btn_facil := Button.new()
	btn_facil.text = "[FÁCIL]  10 vidas"
	btn_facil.icon = PixelSkin.difficulty_icon("FACIL")
	btn_facil.add_theme_font_size_override("font_size", 12)
	btn_facil.custom_minimum_size = Vector2(0, 38)
	PixelSkin.skin_button(btn_facil, PixelSkin.C_GREEN)
	btn_facil.pressed.connect(func(): _on_difficulty_selected("FACIL"))
	vbox.add_child(btn_facil)

	var btn_normal := Button.new()
	btn_normal.text = "[NORMAL]  5 vidas"
	btn_normal.icon = PixelSkin.difficulty_icon("NORMAL")
	btn_normal.add_theme_font_size_override("font_size", 12)
	btn_normal.custom_minimum_size = Vector2(0, 38)
	PixelSkin.skin_button(btn_normal, PixelSkin.C_ORANGE)
	btn_normal.pressed.connect(func(): _on_difficulty_selected("NORMAL"))
	vbox.add_child(btn_normal)

	var btn_ing := Button.new()
	btn_ing.text = "[INGENIERO]  3 vidas"
	btn_ing.icon = PixelSkin.difficulty_icon("INGENIERO")
	btn_ing.add_theme_font_size_override("font_size", 12)
	btn_ing.custom_minimum_size = Vector2(0, 38)
	PixelSkin.skin_button(btn_ing, PixelSkin.C_RED)
	btn_ing.pressed.connect(func(): _on_difficulty_selected("INGENIERO"))
	vbox.add_child(btn_ing)

	var btn_back := Button.new()
	btn_back.text = "←  Ver Instrucciones"
	btn_back.add_theme_font_size_override("font_size", 11)
	btn_back.custom_minimum_size = Vector2(0, 34)
	PixelSkin.skin_button(btn_back, PixelSkin.C_SLATE)
	btn_back.pressed.connect(func():
		AudioManager.play_click()
		_show_difficulty_selector()
	)
	vbox.add_child(btn_back)


func _build_overlay_instructions() -> void:
	var parts: Array = _create_overlay(Color(0, 0, 0, 0.82))
	instructions_overlay = parts[0]
	var vbox: VBoxContainer = parts[1]

	var title := Label.new()
	title.text = "INSTRUCCIONES"
	title.add_theme_font_size_override("font_size", 15)
	PixelSkin.style_label(title, PixelSkin.C_YELLOW)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	instr_difficulty_label = Label.new()
	instr_difficulty_label.text = "Lluvia de Requerimientos"
	instr_difficulty_label.add_theme_font_size_override("font_size", 10)
	PixelSkin.style_label(instr_difficulty_label, PixelSkin.C_CYAN)
	instr_difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instr_difficulty_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var rules: Array[String] = [
		"[+] Atrapa tarjetas VERDES\n     (Req. Funcionales) = +Puntos",
		"[-] Esquiva bloques NARANJAS\n     (Req. No Funcionales) = -1 Vida",
		"[!] Si un Req. Funcional se\n     escapa por abajo = -1 Vida",
		"[T] Sobrevive hasta que el\n     tiempo termine para ganar",
	]
	for rule_text in rules:
		var rule_lbl := Label.new()
		rule_lbl.text = rule_text
		rule_lbl.add_theme_font_size_override("font_size", 9)
		rule_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		vbox.add_child(rule_lbl)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	var btn_start := Button.new()
	btn_start.text = "▶  Elegir Dificultad"
	btn_start.add_theme_font_size_override("font_size", 14)
	btn_start.custom_minimum_size = Vector2(0, 42)
	PixelSkin.skin_button(btn_start, PixelSkin.C_GREEN)
	btn_start.pressed.connect(_on_start_pressed)
	vbox.add_child(btn_start)

	var btn_change := Button.new()
	btn_change.text = "←  Volver al Salón"
	btn_change.add_theme_font_size_override("font_size", 11)
	btn_change.custom_minimum_size = Vector2(0, 34)
	PixelSkin.skin_button(btn_change, PixelSkin.C_SLATE)
	btn_change.pressed.connect(_on_back_pressed)
	vbox.add_child(btn_change)


func _build_overlay_pause() -> void:
	var parts: Array = _create_overlay(Color(0, 0, 0, 0.70))
	pause_overlay = parts[0]
	var vbox: VBoxContainer = parts[1]

	var title := Label.new()
	title.text = "PAUSA"
	title.add_theme_font_size_override("font_size", 18)
	PixelSkin.style_label(title, PixelSkin.C_YELLOW)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var btn_resume := Button.new()
	btn_resume.text = "▶  Reanudar"
	btn_resume.add_theme_font_size_override("font_size", 13)
	btn_resume.custom_minimum_size = Vector2(0, 40)
	PixelSkin.skin_button(btn_resume, PixelSkin.C_GREEN)
	btn_resume.pressed.connect(_toggle_pause)
	vbox.add_child(btn_resume)

	var btn_salon := Button.new()
	btn_salon.text = "←  Volver al Salón"
	btn_salon.add_theme_font_size_override("font_size", 12)
	btn_salon.custom_minimum_size = Vector2(0, 38)
	PixelSkin.skin_button(btn_salon, PixelSkin.C_SLATE)
	btn_salon.pressed.connect(_on_back_pressed)
	vbox.add_child(btn_salon)


func _build_overlay_game_over() -> void:
	var parts: Array = _create_overlay(Color(0.15, 0, 0, 0.85))
	game_over_overlay = parts[0]
	var vbox: VBoxContainer = parts[1]

	var title := Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_size_override("font_size", 20)
	PixelSkin.style_label(title, PixelSkin.C_RED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	final_score_label = Label.new()
	final_score_label.text = "Puntaje: 0"
	final_score_label.add_theme_font_size_override("font_size", 13)
	PixelSkin.style_label(final_score_label, PixelSkin.C_WHITE)
	final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(final_score_label)

	var btn_retry := Button.new()
	btn_retry.text = "Reiniciar Actividad"
	btn_retry.add_theme_font_size_override("font_size", 13)
	btn_retry.custom_minimum_size = Vector2(0, 40)
	PixelSkin.skin_button(btn_retry, PixelSkin.C_ORANGE)
	btn_retry.pressed.connect(_on_retry_pressed)
	vbox.add_child(btn_retry)

	var btn_salon := Button.new()
	btn_salon.text = "←  Volver al Salón"
	btn_salon.add_theme_font_size_override("font_size", 11)
	btn_salon.custom_minimum_size = Vector2(0, 36)
	PixelSkin.skin_button(btn_salon, PixelSkin.C_SLATE)
	btn_salon.pressed.connect(_on_back_pressed)
	vbox.add_child(btn_salon)


func _build_overlay_victory() -> void:
	var parts: Array = _create_overlay(Color(0, 0.05, 0.1, 0.85))
	victory_overlay = parts[0]
	var vbox: VBoxContainer = parts[1]

	var title := Label.new()
	title.text = "¡COMPLETADO!"
	title.add_theme_font_size_override("font_size", 20)
	PixelSkin.style_label(title, PixelSkin.C_YELLOW)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	victory_stars_row = PixelSkin.make_stars_row(3)
	vbox.add_child(victory_stars_row)

	stars_label = Label.new()
	stars_label.text = "★ ★ ★"
	stars_label.add_theme_font_size_override("font_size", 22)
	stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if victory_stars_row.get_child_count() > 0:
		stars_label.visible = false
	stats_sync_stars(stars_label, victory_stars_row)
	vbox.add_child(stars_label)

	victory_score_label = Label.new()
	victory_score_label.text = "Puntaje: 0"
	victory_score_label.add_theme_font_size_override("font_size", 14)
	PixelSkin.style_label(victory_score_label, PixelSkin.C_WHITE)
	victory_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(victory_score_label)

	# Opciones de salida al finalizar la actividad
	var btn_salon := Button.new()
	btn_salon.text = "←  Volver al Salón"
	btn_salon.add_theme_font_size_override("font_size", 13)
	btn_salon.custom_minimum_size = Vector2(0, 40)
	PixelSkin.skin_button(btn_salon, PixelSkin.C_BLUE)
	btn_salon.pressed.connect(_on_back_pressed)
	vbox.add_child(btn_salon)

	var btn_campus := Button.new()
	btn_campus.text = "←  Salir al Campus"
	btn_campus.add_theme_font_size_override("font_size", 13)
	btn_campus.custom_minimum_size = Vector2(0, 40)
	PixelSkin.skin_button(btn_campus, PixelSkin.C_SLATE)
	btn_campus.pressed.connect(_on_exit_to_campus)
	vbox.add_child(btn_campus)


func stats_sync_stars(lbl: Label, row: HBoxContainer) -> void:
	victory_overlay.visibility_changed.connect(func():
		if victory_overlay.visible:
			PixelSkin.set_stars(row, PixelSkin.count_stars_in_text(lbl.text)))


## StyleBox para tarjeta de requerimiento (textura 9-slice pixel art con respaldo plano)
func _make_req_stylebox(is_functional: bool, is_acc: bool) -> StyleBox:
	var tex_name: String
	if is_functional:
		tex_name = "card_rf_hc_9.png" if is_acc else "card_rf_9.png"
	else:
		tex_name = "card_rnf_hc_9.png" if is_acc else "card_rnf_9.png"
	var sb_tex := PixelSkin.style_9(ASSETS_DIR + tex_name, 6, Color.WHITE, 4)
	if sb_tex != null:
		return sb_tex
	var bg_col: Color
	var bdr_col: Color
	if is_functional:
		bg_col = Color("#0072B2") if is_acc else Color(0.18, 0.52, 0.18)
		bdr_col = Color("#56B4E9") if is_acc else Color(0.12, 0.38, 0.12)
	else:
		bg_col = Color("#D55E00") if is_acc else Color(0.65, 0.14, 0.14)
		bdr_col = Color("#E69F00") if is_acc else Color(0.48, 0.10, 0.10)
	var bdr_w: int = 3 if is_acc else 2
	return _make_stylebox(bg_col, 5, bdr_w, bdr_col)

# ══════════════════════════════════════════════════════════════════════════════
# HELPERS DE UI
# ══════════════════════════════════════════════════════════════════════════════

func _make_stylebox(color: Color, corner_radius: int = 4, border_width: int = 0, border_color: Color = Color.BLACK) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(corner_radius)
	if border_width > 0:
		sb.border_width_left = border_width
		sb.border_width_right = border_width
		sb.border_width_top = border_width
		sb.border_width_bottom = border_width
		sb.border_color = border_color
	sb.content_margin_left = 4.0
	sb.content_margin_right = 4.0
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	return sb

# ══════════════════════════════════════════════════════════════════════════════
# FLUJO PRE-PARTIDA: Instrucciones → Dificultad → Juego
# ══════════════════════════════════════════════════════════════════════════════

func _show_difficulty_selector() -> void:
	is_game_active = false
	difficulty_overlay.visible = false
	instructions_overlay.visible = true
	pause_overlay.visible = false
	game_over_overlay.visible = false
	victory_overlay.visible = false


func _on_difficulty_selected(diff: String) -> void:
	AudioManager.play_click()
	selected_difficulty = diff
	_configure_difficulty(diff)

	# Actualizar label de instrucciones con la dificultad elegida
	var diff_names := {"FACIL": "FÁCIL", "NORMAL": "NORMAL", "INGENIERO": "INGENIERO"}
	instr_difficulty_label.text = "Dificultad: %s — %d vidas" % [diff_names.get(diff, diff), max_lives]

	difficulty_overlay.visible = false
	instructions_overlay.visible = false
	_start_game_play()


func _on_start_pressed() -> void:
	AudioManager.play_click()
	instructions_overlay.visible = false
	difficulty_overlay.visible = true


func _configure_difficulty(diff: String) -> void:
	match diff:
		"FACIL":
			max_lives = 10
			current_lives = 10
			game_duration = 90.0
			spawn_interval_start = 2.5
			spawn_interval_end = 1.5
			fall_speed_start = 100.0
			fall_speed_end = 140.0
			functional_ratio = 0.55
			difficulty_multiplier = 1
		"NORMAL":
			max_lives = 5
			current_lives = 5
			game_duration = 75.0
			spawn_interval_start = 2.0
			spawn_interval_end = 1.0
			fall_speed_start = 120.0
			fall_speed_end = 180.0
			functional_ratio = 0.50
			difficulty_multiplier = 2
		"INGENIERO":
			max_lives = 3
			current_lives = 3
			game_duration = 60.0
			spawn_interval_start = 1.5
			spawn_interval_end = 0.7
			fall_speed_start = 150.0
			fall_speed_end = 220.0
			functional_ratio = 0.40
			difficulty_multiplier = 3


func _start_game_play() -> void:
	super.start_game(selected_difficulty)

	score = 0
	current_lives = max_lives
	time_remaining = game_duration
	spawn_timer = 0.5 # Primer spawn rápido
	is_paused = false
	is_game_active = true
	move_direction = 0

	# Limpiar requerimientos previos
	_clear_active_requirements()

	# Resetear posición de la vagoneta
	player_cart.position.x = game_area.size.x / 2.0 - CART_WIDTH / 2.0

	# Actualizar HUD
	_update_hud()
	timer_bar.max_value = game_duration
	timer_bar.value = game_duration

	# Emitir señal de inicio al EventBus (diagrama de secuencia)
	EventBus.minigame_started.emit(minigame_id, selected_difficulty)

# ══════════════════════════════════════════════════════════════════════════════
# LÓGICA DEL JUEGO: Spawn, Caída, Colisiones
# ══════════════════════════════════════════════════════════════════════════════

func _spawn_requirement() -> void:
	var is_functional: bool = randf() < functional_ratio
	var text_pool: Array = FUNCTIONAL_REQS if is_functional else NON_FUNCTIONAL_REQS
	var req_text: String = text_pool[randi() % text_pool.size()]

	# ── Crear nodo visual del requerimiento (mantiene REQ_WIDTH x REQ_HEIGHT exactos) ──
	var req_node := PanelContainer.new()
	req_node.custom_minimum_size = Vector2(REQ_WIDTH, REQ_HEIGHT)
	req_node.set_meta("is_functional", is_functional)

	var type_text: String = "RF" if is_functional else "RNF"
	var is_acc: bool = StateManager.is_high_contrast_active() if StateManager else false
	req_node.add_theme_stylebox_override("panel", _make_req_stylebox(is_functional, is_acc))

	# Contenido de la tarjeta: encabezado con icono pixel (engranaje RF / cronómetro RNF) + texto
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 3)
	var icon_name: String = "icon_gear.png" if is_functional else "icon_stopwatch.png"
	var icon_tex := PixelSkin.tex(ASSETS_DIR + icon_name)
	if icon_tex != null:
		header.add_child(PixelSkin.icon(icon_tex, Vector2(14, 14)))

	var type_label := Label.new()
	type_label.text = type_text
	type_label.add_theme_font_size_override("font_size", 9)
	PixelSkin.style_label(type_label, PixelSkin.C_WHITE, 2)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(type_label)
	vbox.add_child(header)

	var text_label := Label.new()
	text_label.text = req_text
	text_label.add_theme_font_size_override("font_size", 8)
	text_label.add_theme_color_override("font_color", Color.WHITE)
	text_label.add_theme_color_override("font_outline_color", PixelSkin.C_INK)
	text_label.add_theme_constant_override("outline_size", 2)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(text_label)

	req_node.add_child(vbox)

	# Posición inicial: bajo la nube, X aleatorio
	var max_x: float = game_area.size.x - REQ_WIDTH
	req_node.position = Vector2(randf_range(4, maxf(max_x, 5)), 45.0)

	game_area.add_child(req_node)
	active_requirements.append(req_node)


func _update_requirements(delta: float) -> void:
	var current_speed: float = _get_current_fall_speed()
	var to_remove: Array = []

	for req in active_requirements:
		if not is_instance_valid(req):
			to_remove.append(req)
			continue

		# Mover hacia abajo
		req.position.y += current_speed * delta

		# Verificar colisión con la vagoneta
		var req_rect := Rect2(req.position, Vector2(REQ_WIDTH, REQ_HEIGHT))
		var cart_rect := Rect2(player_cart.position, Vector2(CART_WIDTH, CART_HEIGHT))

		if req_rect.intersects(cart_rect):
			var is_func: bool = req.get_meta("is_functional")
			if is_func:
				_on_catch_functional(req)
			else:
				_on_catch_non_functional(req)
			to_remove.append(req)
			continue

		# Verificar si salió por abajo (no atrapado)
		if req.position.y > game_area.size.y:
			var is_func: bool = req.get_meta("is_functional")
			if is_func:
				_on_miss_functional(req)
			# No funcional que pasa = correcto (esquivado), sin penalización
			to_remove.append(req)

	# Limpiar nodos removidos
	for req in to_remove:
		active_requirements.erase(req)
		if is_instance_valid(req):
			req.queue_free()

	# Verificar Game Over
	if current_lives <= 0 and is_game_active:
		_handle_game_over()


## Atrapa un requerimiento funcional → acierto (FN-03 / FN-04)
func _on_catch_functional(req_node: PanelContainer) -> void:
	var points: int = 10 * difficulty_multiplier
	score += points
	AudioManager.play_success()
	_show_feedback("+%d" % points, Color(0.2, 1.0, 0.3), req_node.position)
	_update_hud()


## Atrapa un requerimiento NO funcional → penalización (FA-03.01)
func _on_catch_non_functional(req_node: PanelContainer) -> void:
	AudioManager.play_error()
	_show_feedback("-1 ❤", Color(1.0, 0.3, 0.3), req_node.position)
	_deduct_life("Atrapaste un requerimiento NO funcional")


## No atrapa un requerimiento funcional → penalización (FA-03.02)
func _on_miss_functional(req_node: PanelContainer) -> void:
	AudioManager.play_error()
	_show_feedback("¡ESCAPÓ! -1 ❤", Color(1.0, 0.5, 0.2), Vector2(game_area.size.x / 2.0 - 40, game_area.size.y - 60))
	_deduct_life("Se escapó un requerimiento funcional")


func _deduct_life(reason: String) -> void:
	current_lives = maxi(0, current_lives - 1)
	_update_hud()
	_flash_screen_red()
	EventBus.life_lost.emit(current_lives)

# ══════════════════════════════════════════════════════════════════════════════
# GAME OVER / VICTORIA / PAUSA
# ══════════════════════════════════════════════════════════════════════════════

## FA-05.01: Sin vidas disponibles → Game Over
func _handle_game_over() -> void:
	is_game_active = false
	AudioManager.play_game_over()
	EventBus.game_over.emit(minigame_id)

	# Registrar resultado en StateManager (diagrama: "Registra el resultado" → "Guarda los datos")
	finish_game(false, score, 0, "Game Over — Sin vidas restantes")

	# Mostrar overlay (diagrama: "Ofrece salir al menú o reiniciar")
	_clear_active_requirements()
	final_score_label.text = "Puntaje: %d" % score
	game_over_overlay.visible = true


## Victoria: el temporizador llega a cero con vidas restantes
func _handle_victory() -> void:
	is_game_active = false
	AudioManager.play_success()

	var earned_stars: int = _calculate_stars()

	# Registrar resultado en StateManager
	finish_game(true, score, earned_stars, "¡Requerimientos clasificados correctamente!")

	# Mostrar overlay de victoria
	_clear_active_requirements()
	victory_score_label.text = "Puntaje: %d" % score
	stars_label.text = "★".repeat(earned_stars) + "☆".repeat(3 - earned_stars)
	victory_overlay.visible = true


func _calculate_stars() -> int:
	var life_ratio: float = float(current_lives) / float(max_lives)
	if life_ratio >= 0.80:
		return 3 # Excelente: conservó ≥80% de vidas
	elif life_ratio >= 0.50:
		return 2 # Bien: conservó ≥50% de vidas
	else:
		return 1 # Sobrevivió


## FA-02.01: Pausa
func _toggle_pause() -> void:
	if not is_game_active:
		return
	is_paused = !is_paused
	pause_overlay.visible = is_paused
	AudioManager.play_click()

# ══════════════════════════════════════════════════════════════════════════════
# UTILIDADES
# ══════════════════════════════════════════════════════════════════════════════

func _get_current_fall_speed() -> float:
	var progress: float = 1.0 - (time_remaining / game_duration)
	return lerpf(fall_speed_start, fall_speed_end, clampf(progress, 0.0, 1.0))


func _get_current_spawn_interval() -> float:
	var progress: float = 1.0 - (time_remaining / game_duration)
	return lerpf(spawn_interval_start, spawn_interval_end, clampf(progress, 0.0, 1.0))


func _update_hud() -> void:
	lives_label.text = "VIDAS: %d" % current_lives
	score_label.text = "%d" % score
	if PixelSkin.set_hearts(hearts_bar, current_lives, max_lives):
		lives_label.visible = false
	else:
		lives_label.visible = true


func _update_timer_bar() -> void:
	timer_bar.value = maxf(time_remaining, 0.0)
	if is_instance_valid(time_label):
		var secs: int = maxi(int(ceil(time_remaining)), 0)
		time_label.text = "%02d:%02d" % [secs / 60, secs % 60]

	# Cambiar color cuando queda poco tiempo
	var has_pixel_bar: bool = PixelSkin.bar_background() != null
	if time_remaining < game_duration * 0.25:
		timer_bar.add_theme_stylebox_override("fill", PixelSkin.bar_fill(PixelSkin.C_RED) if has_pixel_bar else _make_stylebox(Color(0.85, 0.2, 0.15), 3))
	elif time_remaining < game_duration * 0.50:
		timer_bar.add_theme_stylebox_override("fill", PixelSkin.bar_fill(PixelSkin.C_YELLOW) if has_pixel_bar else _make_stylebox(Color(0.85, 0.65, 0.1), 3))
	else:
		timer_bar.add_theme_stylebox_override("fill", PixelSkin.bar_fill(PixelSkin.C_GREEN) if has_pixel_bar else _make_stylebox(Color(0.22, 0.65, 0.30), 3))

	# Animación visual de pasos del desarrollador mientras se mueve
	if is_instance_valid(dev_sprite) and not dev_frames.is_empty():
		var moving: bool = move_direction != 0 or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
		if moving:
			dev_anim_clock += get_process_delta_time() * 9.0
			dev_sprite.texture = dev_frames[int(dev_anim_clock) % dev_frames.size()]
		else:
			dev_sprite.texture = dev_frames[0]


func _clear_active_requirements() -> void:
	for req in active_requirements:
		if is_instance_valid(req):
			req.queue_free()
	active_requirements.clear()


## Muestra un texto de feedback flotante (+10, -1 vida, etc.)
func _show_feedback(text: String, color: Color, pos: Vector2) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.position = pos
	lbl.z_index = 10
	game_area.add_child(lbl)

	var tween := create_tween()
	tween.tween_property(lbl, "position:y", pos.y - 35.0, 0.7)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7)
	tween.tween_callback(lbl.queue_free)


## Flash rojo en pantalla al perder una vida
func _flash_screen_red() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 0, 0, 0.25)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 8
	add_child(flash)

	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

# ══════════════════════════════════════════════════════════════════════════════
# NAVEGACIÓN
# ══════════════════════════════════════════════════════════════════════════════

func _on_retry_pressed() -> void:
	AudioManager.play_click()
	game_over_overlay.visible = false
	# Reinicio inmediato con la misma dificultad (FA-05.01: "reiniciar la actividad de forma inmediata")
	_start_game_play()


func _on_continue_pressed() -> void:
	AudioManager.play_click()
	_on_back_pressed()


func _on_back_pressed() -> void:
	AudioManager.play_click()
	is_game_active = false
	_clear_active_requirements()
	if ResourceLoader.exists("res://scenes/classroom/AulaIngSoftware.tscn"):
		get_tree().change_scene_to_file("res://scenes/classroom/AulaIngSoftware.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/campus/Lobby.tscn")


func _on_exit_to_campus() -> void:
	AudioManager.play_click()
	is_game_active = false
	_clear_active_requirements()
	get_tree().change_scene_to_file("res://scenes/campus/Lobby.tscn")

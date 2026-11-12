## PixelSkin.gd — Utilidades visuales pixel art compartidas (minijuegos de Ingeniería de Software).
## SOLO presentación: no contiene ni modifica estado de juego. Si un asset no existe o aún no fue
## importado por Godot, las funciones devuelven null y cada minijuego conserva su estilo plano anterior.
## Assets generados con pixeling/tools/pixelart/ (paleta Sweetie-16 extendida, exportados a escala x2).
## Responsable: Karol Christopher Espino Galicia
class_name PixelSkin
extends RefCounted

const COMMON_DIR: String = "res://assets/ing_software/comun/"
const FONT_PATH: String = "res://assets/ing_software/comun/fuente/PixelifySans.ttf"

## A partir de este número de vidas se usa el formato compacto (1 corazón + "x/y")
const MAX_HEART_ICONS: int = 6

## Paleta Sweetie-16 extendida (mismos valores que tools/pixelart/PixelArt.psm1)
const C_INK: Color = Color("1a1c2c")
const C_PURPLE: Color = Color("5d275d")
const C_RED: Color = Color("b13e53")
const C_ORANGE: Color = Color("ef7d57")
const C_YELLOW: Color = Color("ffcd75")
const C_LIME: Color = Color("a7f070")
const C_GREEN: Color = Color("38b764")
const C_TEAL: Color = Color("257179")
const C_NAVY: Color = Color("29366f")
const C_BLUE: Color = Color("3b5dc9")
const C_SKY: Color = Color("41a6f6")
const C_CYAN: Color = Color("73eff7")
const C_WHITE: Color = Color("f4f4f4")
const C_SILVER: Color = Color("94b0c2")
const C_GREY: Color = Color("566c86")
const C_SLATE: Color = Color("333c57")
const C_WOOD_DARK: Color = Color("3b2416")
const C_WOOD: Color = Color("6b4226")
const C_WOOD_LIGHT: Color = Color("9c6b3c")
const C_PARCHMENT_DARK: Color = Color("d9a066")
const C_PARCHMENT: Color = Color("eedbb0")

static var _tex_cache: Dictionary = {}
static var _font: Font = null
static var _font_loaded: bool = false

# ── Carga de recursos ─────────────────────────────────────────────────────────

## Carga (con caché) una textura. Devuelve null si no existe o no está importada.
static func tex(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	_tex_cache[path] = t
	return t

## Atajo para assets de la carpeta común (p. ej. "hud/heart_full.png").
static func common(rel_path: String) -> Texture2D:
	return tex(COMMON_DIR + rel_path)

## Fuente pixel (Pixelify Sans, OFL). null si no está disponible.
static func font() -> Font:
	if not _font_loaded:
		_font_loaded = true
		if ResourceLoader.exists(FONT_PATH):
			_font = load(FONT_PATH) as Font
	return _font

## Aplica la fuente pixel a un Control con texto (Label/Button). Se usa en títulos, HUD y botones;
## los textos didácticos largos conservan la fuente por defecto para máxima legibilidad.
static func apply_font(ctrl: Control) -> void:
	var f := font()
	if f != null and is_instance_valid(ctrl):
		ctrl.add_theme_font_override("font", f)

# ── StyleBoxes ────────────────────────────────────────────────────────────────

## StyleBoxTexture 9-slice. margin = borde del 9-slice en px de textura.
static func style_9(path: String, margin: int, modulate: Color = Color.WHITE, content_margin: int = -1) -> StyleBoxTexture:
	var t := tex(path)
	if t == null:
		return null
	var sb := StyleBoxTexture.new()
	sb.texture = t
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = margin
	sb.modulate_color = modulate
	if content_margin >= 0:
		sb.content_margin_left = content_margin
		sb.content_margin_right = content_margin
		sb.content_margin_top = content_margin
		sb.content_margin_bottom = content_margin
	return sb

## Panel oscuro común (modales).
static func dark_panel(content_margin: int = -1) -> StyleBoxTexture:
	return style_9(COMMON_DIR + "ui/panel_dark_9.png", 6, Color.WHITE, content_margin)

## Fondo de barra de progreso.
static func bar_background() -> StyleBoxTexture:
	return style_9(COMMON_DIR + "ui/bar_bg_9.png", 4)

## Relleno plano de barra (sin esquinas redondeadas, estilo pixel).
static func bar_fill(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(0)
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	sb.expand_margin_top = -2
	sb.expand_margin_bottom = -2
	sb.expand_margin_left = -2
	sb.expand_margin_right = -2
	return sb

## Aplica a un botón la piel 9-slice gris teñida con `color`. Si los assets no existen, no hace nada
## (el botón conserva su estilo anterior). Las texturas de los botones se aclaran al teñirse, por eso
## el color se ilumina un poco para conservar el tono original.
static func skin_button(btn: Button, color: Color, normal_path: String = "", pressed_path: String = "", disabled_path: String = "", margin: int = 6) -> void:
	if not is_instance_valid(btn):
		return
	if normal_path == "":
		normal_path = COMMON_DIR + "ui/btn_normal_9.png"
	if pressed_path == "":
		pressed_path = COMMON_DIR + "ui/btn_pressed_9.png"
	if disabled_path == "":
		disabled_path = COMMON_DIR + "ui/btn_disabled_9.png"
	var tint: Color = color.lightened(0.35)
	var sb_normal := style_9(normal_path, margin, tint)
	if sb_normal == null:
		return
	_set_button_padding(sb_normal, 0)
	var sb_hover := style_9(normal_path, margin, tint.lightened(0.15))
	_set_button_padding(sb_hover, 0)
	var sb_pressed := style_9(pressed_path, margin, tint.darkened(0.1))
	if sb_pressed == null:
		sb_pressed = sb_hover
	_set_button_padding(sb_pressed, 2)
	var sb_disabled := style_9(disabled_path, margin, Color(1, 1, 1, 0.75))
	if sb_disabled == null:
		sb_disabled = sb_normal
	_set_button_padding(sb_disabled, 0)
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("hover_pressed", sb_pressed)
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	# Si el botón solo tiene icono (sin texto), centrarlo dentro del recuadro
	if btn.text == "" and btn.icon != null:
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_color_override("font_color", C_WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", C_YELLOW)
	btn.add_theme_color_override("font_outline_color", C_INK)
	btn.add_theme_constant_override("outline_size", 3)
	apply_font(btn)

static func _set_button_padding(sb: StyleBox, sink: int) -> void:
	if sb == null:
		return
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4 + sink
	sb.content_margin_bottom = 4 - sink

# ── Nodos reutilizables ───────────────────────────────────────────────────────

## TextureRect con filtro nearest. Si `size` es cero usa el tamaño natural de la textura.
static func icon(t: Texture2D, size: Vector2 = Vector2.ZERO) -> TextureRect:
	var r := TextureRect.new()
	r.texture = t
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if size != Vector2.ZERO:
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.custom_minimum_size = size
	return r

## Fondo a pantalla completa (TextureRect escalado). null si la textura no existe.
static func full_rect_background(path: String) -> TextureRect:
	var t := tex(path)
	if t == null:
		return null
	var r := TextureRect.new()
	r.texture = t
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return r

## Fondo con textura repetida (tile) a pantalla completa.
static func tiled_background(path: String) -> TextureRect:
	var t := tex(path)
	if t == null:
		return null
	var r := TextureRect.new()
	r.texture = t
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_TILE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return r

## Contenedor de corazones. Se actualiza con set_hearts(); solo dibuja los valores que recibe.
static func make_hearts_bar() -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.name = "HeartsBar"
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_constant_override("separation", 1)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	return bar

## Dibuja `current` corazones llenos de `max_value`. No altera ninguna variable del juego.
## Devuelve false si los assets no están disponibles (para que el juego muestre su texto de respaldo).
static func set_hearts(bar: HBoxContainer, current: int, max_value: int) -> bool:
	if not is_instance_valid(bar):
		return false
	var full := common("hud/heart_full.png")
	var empty := common("hud/heart_empty.png")
	if full == null or empty == null:
		bar.visible = false
		return false
	bar.visible = true
	var key := "%d/%d" % [current, max_value]
	if bar.get_meta("hearts_key", "") == key:
		return true
	bar.set_meta("hearts_key", key)
	for c in bar.get_children():
		bar.remove_child(c)
		c.queue_free()
	if max_value > MAX_HEART_ICONS:
		bar.add_child(icon(full))
		var lbl := Label.new()
		lbl.text = "%d/%d" % [maxi(current, 0), max_value]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", C_WHITE)
		lbl.add_theme_color_override("font_outline_color", C_INK)
		lbl.add_theme_constant_override("outline_size", 3)
		apply_font(lbl)
		bar.add_child(lbl)
	else:
		for i in range(max_value):
			bar.add_child(icon(full if i < current else empty))
	return true

## Fila de estrellas para el overlay de victoria (solo dibujo).
static func make_stars_row(stars: int, total: int = 3) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "StarsRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	var full := common("hud/star_full.png")
	var empty := common("hud/star_empty.png")
	if full == null or empty == null:
		return row
	for i in range(total):
		row.add_child(icon(full if i < stars else empty, Vector2(36, 36)))
	return row

## Actualiza una fila de estrellas creada con make_stars_row() y anima su aparición.
static func set_stars(row: HBoxContainer, stars: int) -> void:
	if not is_instance_valid(row):
		return
	var full := common("hud/star_full.png")
	var empty := common("hud/star_empty.png")
	if full == null or empty == null:
		return
	var i := 0
	for c in row.get_children():
		if c is TextureRect:
			(c as TextureRect).texture = full if i < stars else empty
			c.pivot_offset = Vector2(18, 18)
			c.scale = Vector2.ZERO
			var tw := c.create_tween()
			tw.tween_interval(0.15 + i * 0.2)
			tw.tween_property(c, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			i += 1

## Cuenta las estrellas de un texto tipo "⭐⭐☆" (para reflejar lo que el juego ya calculó).
static func count_stars_in_text(text: String) -> int:
	return text.count("⭐") + text.count("★")

## Icono de dificultad por clave (FACIL / NORMAL / INGENIERO).
static func difficulty_icon(diff_key: String) -> Texture2D:
	match diff_key:
		"FACIL":
			return common("ui/diff_facil.png")
		"INGENIERO":
			return common("ui/diff_ingeniero.png")
		_:
			return common("ui/diff_normal.png")

## Marca estilo pixel a una etiqueta: fuente pixel + contorno oscuro.
static func style_label(lbl: Label, color: Color = C_WHITE, outline: int = 3) -> void:
	if not is_instance_valid(lbl):
		return
	apply_font(lbl)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", C_INK)
	lbl.add_theme_constant_override("outline_size", outline)


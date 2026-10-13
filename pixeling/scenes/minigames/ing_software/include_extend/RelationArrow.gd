## RelationArrow.gd — Conector UML entre dos casos de uso (CU-08: ¿Include o Extend?)
## Dibuja la relación entre el caso base (izquierda) y el caso relacionado (derecha).
##  - NEUTRAL: línea punteada SIN punta + "?"  → no delata la respuesta durante la pregunta.
##  - INCLUDE: flecha punteada base → incluido      con estereotipo «include».
##  - EXTEND:  flecha punteada extensión → base     con estereotipo «extend».
## Responsable: Karol Christopher Espino Galicia
extends Control

enum Mode { HIDDEN, NEUTRAL, INCLUDE, EXTEND }

const DASH_LENGTH: float = 5.0
const LINE_WIDTH: float = 2.0
const HEAD_LENGTH: float = 9.0
const HEAD_HALF_WIDTH: float = 6.0

var mode: int = Mode.NEUTRAL
var line_color: Color = Color("e8e6d9")
var accent_color: Color = Color("f2c14e")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Cambia el modo de dibujo y el color de la línea.
func set_mode(new_mode: int, color: Color = Color("e8e6d9")) -> void:
	mode = new_mode
	line_color = color
	queue_redraw()


func _draw() -> void:
	if mode == Mode.HIDDEN:
		return

	var y: float = size.y * 0.5
	var left := Vector2(2.0, y)
	var right := Vector2(size.x - 2.0, y)

	match mode:
		Mode.NEUTRAL:
			draw_dashed_line(left, right, line_color, LINE_WIDTH, DASH_LENGTH)
			_draw_centered_text("?", y - 10.0, 18, accent_color)
		Mode.INCLUDE:
			_draw_dependency_arrow(left, right)
			_draw_centered_text("«include»", y - 8.0, 10, line_color)
		Mode.EXTEND:
			_draw_dependency_arrow(right, left)
			_draw_centered_text("«extend»", y - 8.0, 10, line_color)


## Flecha de dependencia UML: línea punteada con punta abierta.
func _draw_dependency_arrow(from: Vector2, to: Vector2) -> void:
	var dir: Vector2 = (to - from).normalized()
	var perp := Vector2(-dir.y, dir.x)
	draw_dashed_line(from, to - dir * 2.0, line_color, LINE_WIDTH, DASH_LENGTH)
	var base: Vector2 = to - dir * HEAD_LENGTH
	draw_line(to, base + perp * HEAD_HALF_WIDTH, line_color, LINE_WIDTH)
	draw_line(to, base - perp * HEAD_HALF_WIDTH, line_color, LINE_WIDTH)


func _draw_centered_text(text: String, baseline_y: float, font_size: int, color: Color) -> void:
	var font: Font = get_theme_default_font()
	if font == null:
		return
	draw_string(font, Vector2(0.0, baseline_y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, color)

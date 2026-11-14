## LobbyStudentNPC.gd - NPC Estudiante Universitario interactivo para el Lobby
## Morelosoft International Solutions - Pixeling Campus
## Estudiantes universitarios con sprites RPG 16-bit mejorados, animación 4-direccional y reacciones con emojis.
extends Control
class_name LobbyStudentNPC

signal student_clicked(npc: LobbyStudentNPC)

enum State { IDLE, WALKING, REACTING }
enum Direction { SOUTH, NORTH, EAST, WEST }

@export var variant_id: int = 1:
	set(val):
		variant_id = clampi(val, 1, 16)
		if is_node_ready():
			_load_variant_textures()

@export var walk_speed: float = 38.0
@export var wander_bounds: Rect2 = Rect2(60, 200, 240, 360)

var current_state: State = State.IDLE
var current_dir: Direction = Direction.SOUTH

var dir_walk_frames: Dictionary = {
	Direction.SOUTH: [],
	Direction.NORTH: [],
	Direction.EAST: [],
	Direction.WEST: []
}
var dir_idle_textures: Dictionary = {}

var current_frame_idx: int = 0
var anim_timer: float = 0.0
var fps: float = 7.0

var idle_timer: float = 1.5
var reaction_timer: float = 0.0
var target_pos: Vector2 = Vector2.ZERO

var shadow_rect: TextureRect
var sprite_rect: TextureRect
var active_bubble: Control
var hop_tween: Tween

const EMOJI_PATHS: Array[String] = [
	"res://assets/lobby/emojis/emoji_thumbsup.png",
	"res://assets/lobby/emojis/emoji_wilted_rose.png",
	"res://assets/lobby/emojis/emoji_hot_face.png",
	"res://assets/lobby/emojis/emoji_sleeping.png",
	"res://assets/lobby/emojis/emoji_moyai.png",
	"res://assets/lobby/emojis/emoji_pray.png",
	"res://assets/lobby/emojis/emoji_clown.png",
	"res://assets/lobby/emojis/emoji_skull.png",
	"res://assets/lobby/emojis/emoji_sob.png",
	"res://assets/lobby/emojis/emoji_money_mouth.png",
	"res://assets/lobby/emojis/emoji_eyes.png",
	"res://assets/lobby/emojis/emoji_fire.png",
	"res://assets/lobby/emojis/emoji_finger_heart.png"
]

const TEX_BUBBLE = preload("res://assets/lobby/emojis/bubble_frame.png")
const TEX_SHADOW = preload("res://assets/lobby/students/shadow.png")

func _init() -> void:
	custom_minimum_size = Vector2(38, 54)
	size = Vector2(38, 54)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	y_sort_enabled = true

func _ready() -> void:
	_setup_nodes()
	_load_variant_textures()
	walk_speed = randf_range(32.0, 46.0)
	idle_timer = randf_range(0.8, 3.0)
	_pick_new_wander_target()

func _setup_nodes() -> void:
	# 1. Sombra elíptica en los pies
	if not shadow_rect:
		shadow_rect = TextureRect.new()
		shadow_rect.name = "Shadow"
		shadow_rect.texture = TEX_SHADOW
		shadow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shadow_rect.stretch_mode = TextureRect.STRETCH_SCALE
		shadow_rect.custom_minimum_size = Vector2(30, 10)
		shadow_rect.size = Vector2(30, 10)
		shadow_rect.position = Vector2(4, 44)
		shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shadow_rect)

	# 2. Sprite del estudiante con animación de caminata 4-direccional
	if not sprite_rect:
		sprite_rect = TextureRect.new()
		sprite_rect.name = "BodySprite"
		sprite_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite_rect.stretch_mode = TextureRect.STRETCH_SCALE
		sprite_rect.custom_minimum_size = Vector2(38, 54)
		sprite_rect.size = Vector2(38, 54)
		sprite_rect.position = Vector2.ZERO
		sprite_rect.pivot_offset = Vector2(19, 48)
		sprite_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sprite_rect)

func _load_variant_textures() -> void:
	dir_walk_frames[Direction.SOUTH] = []
	dir_walk_frames[Direction.NORTH] = []
	dir_walk_frames[Direction.EAST] = []
	dir_walk_frames[Direction.WEST] = []
	dir_idle_textures.clear()

	var base_path := "res://assets/lobby/students/student_%d" % variant_id

	# Cargar frames direccionales (s, n, e, w)
	var dirs := {
		Direction.SOUTH: "s",
		Direction.NORTH: "n",
		Direction.EAST: "e",
		Direction.WEST: "w"
	}

	for d in dirs.keys():
		var prefix: String = dirs[d]
		for i in range(4):
			var walk_p := "%s/walk_%s_%d.png" % [base_path, prefix, i]
			var walk_tex: Texture2D = _try_load_texture(walk_p)
			if walk_tex:
				dir_walk_frames[d].append(walk_tex)

		var idle_p := "%s/idle_%s.png" % [base_path, prefix]
		var idle_tex: Texture2D = _try_load_texture(idle_p)
		if idle_tex:
			dir_idle_textures[d] = idle_tex

	# Fallback a walk_0..3 clásico si no hay direccionales
	if dir_walk_frames[Direction.SOUTH].is_empty():
		for i in range(4):
			var fallback_p := "%s/walk_%d.png" % [base_path, i]
			var fallback_tex: Texture2D = _try_load_texture(fallback_p)
			if fallback_tex:
				dir_walk_frames[Direction.SOUTH].append(fallback_tex)

	_update_sprite_display()

# Cache estático compartido para todas las instancias de estudiantes y emojis
static var _texture_cache: Dictionary = {}

func _try_load_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	elif FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
	if tex:
		_texture_cache[path] = tex
	return tex

func _get_current_walk_frames() -> Array:
	if dir_walk_frames.has(current_dir) and not dir_walk_frames[current_dir].is_empty():
		return dir_walk_frames[current_dir]
	return dir_walk_frames[Direction.SOUTH]

func _update_sprite_display() -> void:
	if not sprite_rect:
		return
	if dir_idle_textures.has(current_dir):
		sprite_rect.texture = dir_idle_textures[current_dir]
	else:
		var frames := _get_current_walk_frames()
		if not frames.is_empty():
			sprite_rect.texture = frames[0]

func _process(delta: float) -> void:
	if not is_inside_tree() or not is_visible_in_tree() or is_queued_for_deletion():
		return

	match current_state:
		State.REACTING:
			reaction_timer -= delta
			if reaction_timer <= 0.0:
				current_state = State.IDLE
				idle_timer = randf_range(1.2, 3.0)
				_update_sprite_display()

		State.IDLE:
			idle_timer -= delta
			if idle_timer <= 0.0:
				_pick_new_wander_target()
				current_state = State.WALKING

		State.WALKING:
			var to_target := target_pos - position
			var dist := to_target.length()

			if dist < 4.0:
				position = target_pos
				current_state = State.IDLE
				idle_timer = randf_range(2.0, 4.5)
				_update_sprite_display()
			else:
				var move_step := to_target.normalized() * walk_speed * delta
				if move_step.length() > dist:
					position = target_pos
					current_state = State.IDLE
					idle_timer = randf_range(2.0, 4.5)
					_update_sprite_display()
				else:
					position += move_step

				# Determinar dirección cardinal predominante (4 direcciones)
				var ax: float = abs(to_target.x)
				var ay: float = abs(to_target.y)
				if ax >= ay * 0.75:
					current_dir = Direction.EAST if to_target.x > 0 else Direction.WEST
				elif to_target.y > 0:
					current_dir = Direction.SOUTH
				else:
					current_dir = Direction.NORTH

				# Animación de pasos (4 frames a ~7 FPS)
				anim_timer += delta
				if anim_timer >= 1.0 / fps:
					anim_timer = 0.0
					var frames := _get_current_walk_frames()
					if not frames.is_empty():
						current_frame_idx = (current_frame_idx + 1) % frames.size()
						if sprite_rect:
							sprite_rect.texture = frames[current_frame_idx]

func _pick_new_wander_target() -> void:
	if wander_bounds.size == Vector2.ZERO:
		wander_bounds = Rect2(60, 200, 240, 360)

	var tx := randf_range(wander_bounds.position.x, wander_bounds.end.x - size.x)
	var ty := randf_range(wander_bounds.position.y, wander_bounds.end.y - size.y)
	target_pos = Vector2(tx, ty)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		trigger_reaction()
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		trigger_reaction()
		accept_event()

## Dispara la animación de reacción con sonido, rebote y globo de emoji
func trigger_reaction(forced_emoji_path: String = "") -> void:
	if AudioManager:
		AudioManager.play_tone(880.0, 0.08)

	# Al reaccionar, el estudiante se voltea hacia el frente (jugador)
	current_dir = Direction.SOUTH
	_update_sprite_display()

	# Animación física de salto/squash & stretch en el estudiante
	if sprite_rect:
		if hop_tween and hop_tween.is_valid():
			hop_tween.kill()
		hop_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		hop_tween.tween_property(sprite_rect, "scale", Vector2(1.22, 0.78), 0.07)
		hop_tween.tween_property(sprite_rect, "scale", Vector2(0.88, 1.22), 0.12)
		hop_tween.tween_property(sprite_rect, "scale", Vector2.ONE, 0.16)

	current_state = State.REACTING
	reaction_timer = 2.0

	_spawn_emoji_bubble(forced_emoji_path)
	student_clicked.emit(self)

func _spawn_emoji_bubble(forced_emoji_path: String = "") -> void:
	if is_instance_valid(active_bubble):
		active_bubble.queue_free()
		active_bubble = null

	var bubble := Control.new()
	bubble.name = "EmojiBubble"
	bubble.custom_minimum_size = Vector2(36, 36)
	bubble.size = Vector2(36, 36)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.pivot_offset = Vector2(18, 34)

	# Posicionar el globo flotante arriba de la cabeza del estudiante
	var start_pos := Vector2((size.x - 36.0) * 0.5, -42.0)
	bubble.position = start_pos
	bubble.scale = Vector2(0.1, 0.1)

	# Marco del globo de diálogo estilo moderno suave
	var frame_rect := TextureRect.new()
	frame_rect.texture = TEX_BUBBLE
	frame_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_rect.stretch_mode = TextureRect.STRETCH_SCALE
	frame_rect.custom_minimum_size = Vector2(36, 36)
	frame_rect.size = Vector2(36, 36)
	frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(frame_rect)

	# Icono de emoji estándar (alta definición, vectorial suave)
	var emoji_path: String = forced_emoji_path
	if emoji_path == "" and not EMOJI_PATHS.is_empty():
		emoji_path = EMOJI_PATHS.pick_random()

	var emoji_tex: Texture2D = _try_load_texture(emoji_path)

	if emoji_tex:
		var emoji_rect := TextureRect.new()
		emoji_rect.texture = emoji_tex
		emoji_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		emoji_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emoji_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emoji_rect.custom_minimum_size = Vector2(24, 24)
		emoji_rect.size = Vector2(24, 24)
		emoji_rect.position = Vector2(6, 2)
		emoji_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bubble.add_child(emoji_rect)

	add_child(bubble)
	active_bubble = bubble

	# Animación de aparición (pop bounce Balatro), flotación hacia arriba y desvanecimiento
	var b_tween := create_tween()
	b_tween.tween_property(bubble, "scale", Vector2(1.25, 1.25), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	b_tween.tween_property(bubble, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	b_tween.parallel().tween_property(bubble, "position:y", start_pos.y - 22.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	b_tween.tween_property(bubble, "modulate:a", 0.0, 0.35).set_delay(1.1)
	b_tween.tween_callback(bubble.queue_free)

## LoadingScreen.gd - Pantalla de carga inicial de PixelIng
## Cumple con la especificación visual y transición automática al Lobby
extends Control

@onready var progress_bar: ProgressBar = $BottomLoading/ProgressBar
@onready var lbl_loading: Label = $BottomLoading/LoadingLabel
@onready var fade_overlay: ColorRect = $FadeOverlay

const LOAD_DURATION: float = 5.0
const FADE_DURATION: float = 0.8
const TARGET_SCENE: String = "res://scenes/campus/Lobby.tscn"

var _elapsed_time: float = 0.0
var _is_transitioning: bool = false

func _ready() -> void:
	fade_overlay.color = Color(0, 0, 0, 0)
	progress_bar.value = 0.0
	
	# Animar barra de progreso a lo largo de los 5 segundos
	var tween := create_tween()
	tween.tween_property(progress_bar, "value", 100.0, LOAD_DURATION)
	
	# Iniciar temporizador de 5 segundos
	var timer := get_tree().create_timer(LOAD_DURATION)
	timer.timeout.connect(_start_fade_transition)

func _process(delta: float) -> void:
	if _is_transitioning:
		return
	_elapsed_time += delta
	# Efecto de puntos suspensivos pulsantes en el texto de carga
	var dots := int(_elapsed_time * 2.0) % 4
	lbl_loading.text = "Cargando Campus Virtual" + ".".repeat(dots)

func _start_fade_transition() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	lbl_loading.text = "¡Listo!"
	
	# Transición de degradado suave (Fade to Black) al Lobby Central
	var fade_tween := create_tween()
	fade_tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1.0), FADE_DURATION)
	fade_tween.finished.connect(func():
		get_tree().change_scene_to_file(TARGET_SCENE)
	)

class_name VictoryModal
extends Control

signal continue_requested
signal play_again_requested
signal exit_requested

@onready var anim_panel: Control = $Center/PanelContainer
@onready var title_label: Label = $Center/PanelContainer/Margin/VBox/HeaderBox/TitleLabel
@onready var stars_desc: Label = $Center/PanelContainer/Margin/VBox/HeaderBox/StarsDesc
@onready var stars_label: Label = $Center/PanelContainer/Margin/VBox/StarsBox/StarsIcons
@onready var score_val_label: Label = $Center/PanelContainer/Margin/VBox/InnerPlate/StatsBox/ScoreRow/ValLabel
@onready var total_val_label: Label = $Center/PanelContainer/Margin/VBox/InnerPlate/StatsBox/TotalRow/ValLabel
@onready var record_badge: Label = $Center/PanelContainer/Margin/VBox/InnerPlate/StatsBox/RecordBadge
@onready var btn_play_again: Button = $Center/PanelContainer/Margin/VBox/ButtonsContainer/BtnPlayAgain
@onready var btn_exit: Button = $Center/PanelContainer/Margin/VBox/ButtonsContainer/BtnExit

var _active_tween: Tween = null

func _ready() -> void:
	btn_play_again.pressed.connect(_on_play_again_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

func open(score: int, stars: int = 3, total_points: int = -1, is_new_record: bool = false, custom_title: String = "") -> void:
	if AudioManager and AudioManager.has_method("play_success"):
		AudioManager.play_success()
	if not custom_title.is_empty():
		title_label.text = custom_title
	else:
		title_label.text = "¡MISIÓN CUMPLIDA!"

	# Mostrar estrellas obtenidas (1 a 3)
	var clamped_stars := clampi(stars, 0, 3)
	var star_icons := ""
	for i in range(3):
		if i < clamped_stars:
			star_icons += " ★ "
		else:
			star_icons += " ☆ "
	stars_label.text = star_icons.strip_edges()

	match clamped_stars:
		3:
			stars_desc.text = "¡DESEMPEÑO IMPECABLE! (3 ESTRELLAS)"
			stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		2:
			stars_desc.text = "¡BUEN TRABAJO DE INGENIERÍA! (2 ESTRELLAS)"
			stars_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.25))
		_:
			stars_desc.text = "¡MISIÓN COMPLETADA! (1 ESTRELLA)"
			stars_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))

	score_val_label.text = "+%d PTS" % score

	# Economía real según especificación: solo existe el contador acumulado de Puntos
	var accumulated: int = total_points
	if StateManager and StateManager.has_method("get_points"):
		accumulated = StateManager.get_points()
	elif accumulated < 0:
		accumulated = score
	total_val_label.text = "%d PTS" % accumulated

	record_badge.visible = is_new_record

	if is_instance_valid(_active_tween) and _active_tween.is_running():
		_active_tween.kill()
	visible = true
	anim_panel.scale = Vector2(0.82, 0.82)
	anim_panel.modulate.a = 0.0
	_active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(anim_panel, "scale", Vector2.ONE, 0.24)
	_active_tween.tween_property(anim_panel, "modulate:a", 1.0, 0.2)

	stars_label.pivot_offset = stars_label.size * 0.5
	stars_label.scale = Vector2(0.5, 0.5)
	var tw_star = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw_star.tween_property(stars_label, "scale", Vector2.ONE, 0.4).set_delay(0.1)

func close() -> void:
	if is_instance_valid(_active_tween) and _active_tween.is_running():
		_active_tween.kill()
	if not visible:
		return
	if anim_panel:
		_active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_active_tween.tween_property(anim_panel, "scale", Vector2(0.9, 0.9), 0.12)
		_active_tween.tween_property(anim_panel, "modulate:a", 0.0, 0.12)
		_active_tween.finished.connect(func():
			if is_instance_valid(self):
				visible = false
		)
	else:
		visible = false

func _on_play_again_pressed() -> void:
	if AudioManager and AudioManager.has_method("play_click"):
		AudioManager.play_click()
	play_again_requested.emit()
	close()

func _on_exit_pressed() -> void:
	if AudioManager and AudioManager.has_method("play_click"):
		AudioManager.play_click()
	exit_requested.emit()
	close()

extends Control

@onready var modal_diff: Control = $Modals/DifficultyModal
@onready var modal_pause: Control = $Modals/PauseModal
@onready var modal_victory: Control = $Modals/VictoryModal
@onready var modal_gameover: Control = $Modals/GameOverModal
@onready var modal_tutorial: Control = $Modals/TutorialModal
@onready var modal_settings: Control = $Modals/SettingsModal

@onready var badge_label: Label = $Scroll/Content/HeaderPanel/Margin/VBox/BranchBadge
@onready var btn_toggle_pack: Button = $Scroll/Content/SwitcherBox/BtnTogglePack
@onready var switcher_desc: Label = $Scroll/Content/SwitcherBox/SwitcherDesc

@onready var btn_sample_green: Button = $Scroll/Content/ShowroomPanel/Margin/VBox/ButtonsGrid/BtnSampleGreen
@onready var btn_sample_blue: Button = $Scroll/Content/ShowroomPanel/Margin/VBox/ButtonsGrid/BtnSampleBlue
@onready var btn_sample_yellow: Button = $Scroll/Content/ShowroomPanel/Margin/VBox/ButtonsGrid/BtnSampleYellow
@onready var btn_sample_red: Button = $Scroll/Content/ShowroomPanel/Margin/VBox/ButtonsGrid/BtnSampleRed
@onready var btn_sample_grey: Button = $Scroll/Content/ShowroomPanel/Margin/VBox/ButtonsGrid/BtnSampleGrey
@onready var sample_slider: HSlider = $Scroll/Content/ShowroomPanel/Margin/VBox/ControlsHBox/SliderBox/SampleSlider
@onready var sample_check1: CheckBox = $Scroll/Content/ShowroomPanel/Margin/VBox/ControlsHBox/ChecksBox/SampleCheck1
@onready var sample_check2: CheckBox = $Scroll/Content/ShowroomPanel/Margin/VBox/ControlsHBox/ChecksBox/SampleCheck2

@onready var btn_test_diff: Button = $Scroll/Content/TriggersBox/BtnTestDiff
@onready var btn_test_pause: Button = $Scroll/Content/TriggersBox/BtnTestPause
@onready var btn_test_victory: Button = $Scroll/Content/TriggersBox/BtnTestVictory
@onready var btn_test_gameover: Button = $Scroll/Content/TriggersBox/BtnTestGameOver
@onready var btn_test_tutorial: Button = $Scroll/Content/TriggersBox/BtnTestTutorial
@onready var btn_test_settings: Button = $Scroll/Content/TriggersBox/BtnTestSettings
@onready var btn_back_to_lobby: Button = $Scroll/Content/TriggersBox/BtnBackToLobby

@onready var log_label: Label = $Scroll/Content/LogPanel/LogMargin/LogVBox/LogScroll/LogLabel

var current_pack: String = "classic"

func _ready() -> void:
	_log("Sistema UI Inicializado. Branch: interfazDEMO")
	_log("Pack Activo por defecto: Kenney Classic UI (PNG/Double 384x128)")
	_log("Soporta relieve 3D táctil, botón plano al presionar y máxima legibilidad.")
	
	# Pack Switcher toggle
	btn_toggle_pack.pressed.connect(_toggle_pack)
	
	# Showroom playground
	btn_sample_green.pressed.connect(func(): _on_sample_btn("Verde / Confirmar (Éxito)"))
	btn_sample_blue.pressed.connect(func(): _on_sample_btn("Azul / Información (Info)"))
	btn_sample_yellow.pressed.connect(func(): _on_sample_btn("Amarillo / Advertencia (Warning)"))
	btn_sample_red.pressed.connect(func(): _on_sample_btn("Rojo / Salir / Peligro (Alert)"))
	btn_sample_grey.pressed.connect(func(): _on_sample_btn("Gris / Neutral / Volver"))
	
	sample_slider.value_changed.connect(func(val):
		_log(">> [SLIDER] Volumen ajustado a: %d%%" % int(val))
	)
	sample_check1.toggled.connect(func(on):
		_log(">> [CHECKBOX] SFX: %s" % ("Activados" if on else "Desactivados"))
		AudioManager.play_click() if AudioManager else null
	)
	sample_check2.toggled.connect(func(on):
		_log(">> [CHECKBOX] Pantalla completa: %s" % ("Sí" if on else "No"))
		AudioManager.play_click() if AudioManager else null
	)

	# Connect modal triggers
	btn_test_diff.pressed.connect(func():
		_log("Abriendo Modal de Selección de Dificultad...")
		modal_diff.open("EXPLORACIÓN DE ARCHIVOS")
	)
	
	btn_test_pause.pressed.connect(func():
		_log("Abriendo Menú de Pausa...")
		modal_pause.open("PAUSA TÁCTICA")
	)
	
	btn_test_victory.pressed.connect(func():
		_log("Abriendo Modal de Victoria...")
		modal_victory.open(500, 3, 50, true, "¡MISIÓN COMPLETADA!")
	)
	
	btn_test_gameover.pressed.connect(func():
		_log("Abriendo Modal de Game Over...")
		modal_gameover.open("Se ha agotado el tiempo límite de la sesión.", 250)
	)
	
	btn_test_tutorial.pressed.connect(func():
		_log("Abriendo Modal de Tutorial / Briefing...")
		modal_tutorial.open()
	)
	
	btn_test_settings.pressed.connect(func():
		_log("Abriendo Modal de Ajustes...")
		modal_settings.open_modal()
	)
	
	btn_back_to_lobby.pressed.connect(_return_to_lobby)
	
	# Connect modal signals
	modal_diff.difficulty_selected.connect(func(diff):
		_log(">> [SEÑAL] Dificultad seleccionada: %s" % diff)
	)
	modal_diff.cancelled.connect(func():
		_log(">> [SEÑAL] Selección de dificultad cancelada / Volver")
	)
	
	modal_pause.resume_requested.connect(func():
		_log(">> [SEÑAL] Pausa: Reanudar misión")
	)
	modal_pause.settings_requested.connect(func():
		_log(">> [SEÑAL] Pausa: Abrir ajustes")
		modal_settings.open_modal()
	)
	modal_pause.restart_requested.connect(func():
		_log(">> [SEÑAL] Pausa: Reiniciar nivel")
	)
	modal_pause.exit_requested.connect(func():
		_log(">> [SEÑAL] Pausa: Salir al aula -> Volviendo al Lobby")
		_return_to_lobby()
	)
	
	modal_victory.continue_requested.connect(func():
		_log(">> [SEÑAL] Victoria: Continuar")
	)
	modal_victory.play_again_requested.connect(func():
		_log(">> [SEÑAL] Victoria: Jugar otra dificultad")
		modal_diff.open()
	)
	modal_victory.exit_requested.connect(func():
		_log(">> [SEÑAL] Victoria: Volver al aula -> Volviendo al Lobby")
		_return_to_lobby()
	)
	
	modal_gameover.retry_requested.connect(func():
		_log(">> [SEÑAL] Game Over: Reintentar")
	)
	modal_gameover.exit_requested.connect(func():
		_log(">> [SEÑAL] Game Over: Salir al aula -> Volviendo al Lobby")
		_return_to_lobby()
	)
	
	modal_tutorial.start_requested.connect(func():
		_log(">> [SEÑAL] Tutorial: Iniciar misión confirmado")
	)

func _on_sample_btn(btn_name: String) -> void:
	AudioManager.play_click() if AudioManager else null
	_log(">> [CLICK] Botón probado: %s" % btn_name)

func _toggle_pack() -> void:
	AudioManager.play_click() if AudioManager else null
	if current_pack == "classic":
		_apply_pack("scifi")
	else:
		_apply_pack("classic")

func _apply_pack(pack_name: String) -> void:
	current_pack = pack_name
	var is_classic = (pack_name == "classic")
	
	badge_label.text = "◆ BRANCH: interfazDEMO · %s ◆" % (
		"KENNEY CLASSIC UI PACK" if is_classic else "KENNEY SCI-FI UI PACK"
	)
	btn_toggle_pack.text = "🎨 PACK ACTIVO: %s (CLIC PARA ALTERNAR A %s)" % [
		"KENNEY CLASSIC" if is_classic else "KENNEY SCI-FI",
		"SCI-FI" if is_classic else "CLASSIC"
	]
	switcher_desc.text = (
		"  * Classic: Botones sólidos uniformes con relieve 3D y hundimiento táctil (sin franjas)."
		if is_classic else
		"  * Sci-Fi: Estilo futurista con franja superior decorativa y tornillería metálica."
	)
	
	_log("--------------------------------------------------")
	_log(">> [TEMA CAMBIADO] Ahora visualizando: %s" % (
		"Kenney Classic UI Pack" if is_classic else "Kenney Sci-Fi UI Pack"
	))
	
	# Dynamic in-memory StyleBox texture hot-swap
	var style_names = [
		"btn_green_normal", "btn_green_hover", "btn_green_pressed",
		"btn_blue_normal", "btn_blue_hover", "btn_blue_pressed",
		"btn_yellow_normal", "btn_yellow_hover", "btn_yellow_pressed",
		"btn_red_normal", "btn_red_hover", "btn_red_pressed",
		"btn_neutral_normal", "btn_neutral_hover", "btn_neutral_pressed", "btn_neutral_disabled",
		"panel_screws", "panel_rect", "panel_rect_screws", "panel_inner_plate", "panel_glass",
		"tab_cyan", "tab_green", "tab_red", "tab_grey"
	]
	
	for s_name in style_names:
		var src_path = "res://scenes/ui/theme/%s/%s.tres" % [pack_name, s_name]
		var dst_path = "res://scenes/ui/theme/%s.tres" % s_name
		if ResourceLoader.exists(src_path) and ResourceLoader.exists(dst_path):
			var src_box = load(src_path)
			var dst_box = load(dst_path)
			if src_box is StyleBoxTexture and dst_box is StyleBoxTexture:
				dst_box.texture = src_box.texture
				dst_box.texture_margin_left = src_box.texture_margin_left
				dst_box.texture_margin_top = src_box.texture_margin_top
				dst_box.texture_margin_right = src_box.texture_margin_right
				dst_box.texture_margin_bottom = src_box.texture_margin_bottom
				dst_box.content_margin_left = src_box.content_margin_left
				dst_box.content_margin_top = src_box.content_margin_top
				dst_box.content_margin_right = src_box.content_margin_right
				dst_box.content_margin_bottom = src_box.content_margin_bottom
				dst_box.modulate_color = src_box.modulate_color

func _return_to_lobby() -> void:
	AudioManager.play_click() if AudioManager else null
	_log(">> [VOLVER] Navegando de regreso al Campus / Lobby...")
	get_tree().change_scene_to_file("res://scenes/campus/Lobby.tscn")

func _log(msg: String) -> void:
	print("[UIDemo] ", msg)
	if log_label:
		log_label.text += "\n" + msg

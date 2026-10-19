## SettingsModal.gd - CU-01: Configurar entorno
## Modal de configuración transaccional por pestañas (Audio, Visual, Accesibilidad)
## Morelosoft International Solutions - PixelIng
extends Control

# Pestañas
@onready var btn_tab_audio: Button = $Center/ModalPanel/Margin/VBox/TabsHeader/BtnTabAudio
@onready var btn_tab_visual: Button = $Center/ModalPanel/Margin/VBox/TabsHeader/BtnTabVisual
@onready var btn_tab_access: Button = $Center/ModalPanel/Margin/VBox/TabsHeader/BtnTabAccess

@onready var tab_audio: VBoxContainer = $Center/ModalPanel/Margin/VBox/TabContent/TabAudio
@onready var tab_visual: VBoxContainer = $Center/ModalPanel/Margin/VBox/TabContent/TabVisual
@onready var tab_access: VBoxContainer = $Center/ModalPanel/Margin/VBox/TabContent/TabAccessibility

# Controles Audio
@onready var slider_sfx: HSlider = $Center/ModalPanel/Margin/VBox/TabContent/TabAudio/SFXRow/SliderSFX
@onready var label_sfx_val: Label = $Center/ModalPanel/Margin/VBox/TabContent/TabAudio/SFXRow/LabelSFXVal
@onready var slider_music: HSlider = $Center/ModalPanel/Margin/VBox/TabContent/TabAudio/MusicRow/SliderMusic
@onready var label_music_val: Label = $Center/ModalPanel/Margin/VBox/TabContent/TabAudio/MusicRow/LabelMusicVal

# Controles Visual (Filtro de Luz Azul)
@onready var check_blue_light: CheckButton = $Center/ModalPanel/Margin/VBox/TabContent/TabVisual/RowBlueLight/CheckBlueLight
@onready var label_blue_light_hint: Label = $Center/ModalPanel/Margin/VBox/TabContent/TabVisual/LabelBlueLightHint

# Controles Accesibilidad (Modo Daltónico / Alto Contraste)
@onready var check_contrast: CheckButton = $Center/ModalPanel/Margin/VBox/TabContent/TabAccessibility/RowContrast/CheckContrast
@onready var label_contrast_hint: Label = $Center/ModalPanel/Margin/VBox/TabContent/TabAccessibility/LabelContrastHint

# Botones Inferiores
@onready var btn_reset: Button = $Center/ModalPanel/Margin/VBox/ActionsHBox/BtnReset
@onready var btn_cancel: Button = $Center/ModalPanel/Margin/VBox/ActionsHBox/BtnCancel
@onready var btn_save: Button = $Center/ModalPanel/Margin/VBox/ActionsHBox/BtnSave

var _backup_settings: Dictionary = {}
var _working_settings: Dictionary = {}
var _is_updating_ui: bool = false
var _is_saved: bool = false

enum Tab { AUDIO, VISUAL, ACCESS }
var _current_tab: Tab = Tab.AUDIO

func _ready() -> void:
	visible = false
	
	# Pestañas
	btn_tab_audio.pressed.connect(func(): _select_tab(Tab.AUDIO))
	btn_tab_visual.pressed.connect(func(): _select_tab(Tab.VISUAL))
	btn_tab_access.pressed.connect(func(): _select_tab(Tab.ACCESS))
	
	# Controles
	slider_sfx.value_changed.connect(_on_sfx_slider_changed)
	slider_music.value_changed.connect(_on_music_slider_changed)
	check_blue_light.toggled.connect(_on_blue_light_toggled)
	check_contrast.toggled.connect(_on_contrast_toggled)
	
	# Acciones
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_cancel.pressed.connect(_on_cancel_pressed)
	btn_save.pressed.connect(_on_save_pressed)

func open_modal() -> void:
	_backup_settings = StateManager.get_settings().duplicate(true)
	_working_settings = _backup_settings.duplicate(true)
	_is_saved = false
	_sync_ui_from_working()
	_select_tab(Tab.AUDIO)
	visible = true

func _select_tab(target_tab: Tab) -> void:
	AudioManager.play_click()
	_current_tab = target_tab
	
	tab_audio.visible = (target_tab == Tab.AUDIO)
	tab_visual.visible = (target_tab == Tab.VISUAL)
	tab_access.visible = (target_tab == Tab.ACCESS)
	
	# Resaltar botón activo
	_style_tab_button(btn_tab_audio, target_tab == Tab.AUDIO)
	_style_tab_button(btn_tab_visual, target_tab == Tab.VISUAL)
	_style_tab_button(btn_tab_access, target_tab == Tab.ACCESS)

func _style_tab_button(btn: Button, is_active: bool) -> void:
	if is_active:
		btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2, 1.0))
	else:
		btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8, 1.0))

func _sync_ui_from_working() -> void:
	_is_updating_ui = true
	var sfx: float = float(_working_settings.get("sfx_volume", 1.0))
	var music: float = float(_working_settings.get("music_volume", 1.0))
	var blue_light: bool = bool(_working_settings.get("blue_light_filter", false))
	var contrast: bool = bool(_working_settings.get("high_contrast", false))
	
	slider_sfx.value = sfx
	label_sfx_val.text = "%d%%" % int(round(sfx * 100.0))
	
	slider_music.value = music
	label_music_val.text = "%d%%" % int(round(music * 100.0))
	
	check_blue_light.button_pressed = blue_light
	label_blue_light_hint.text = "Filtro cálido: Activado" if blue_light else "Filtro cálido: Desactivado"
	
	check_contrast.button_pressed = contrast
	label_contrast_hint.text = "Alto contraste: Activado" if contrast else "Alto contraste: Desactivado"
	
	_is_updating_ui = false

func _on_sfx_slider_changed(value: float) -> void:
	if _is_updating_ui:
		return
	_working_settings["sfx_volume"] = snappedf(value, 0.05)
	label_sfx_val.text = "%d%%" % int(round(value * 100.0))
	StateManager.preview_settings(_working_settings)
	AudioManager.play_click()

func _on_music_slider_changed(value: float) -> void:
	if _is_updating_ui:
		return
	_working_settings["music_volume"] = snappedf(value, 0.05)
	label_music_val.text = "%d%%" % int(round(value * 100.0))
	StateManager.preview_settings(_working_settings)

func _on_blue_light_toggled(toggled_on: bool) -> void:
	if _is_updating_ui:
		return
	_working_settings["blue_light_filter"] = toggled_on
	label_blue_light_hint.text = "Filtro cálido: Activado" if toggled_on else "Filtro cálido: Desactivado"
	StateManager.preview_settings(_working_settings)
	AudioManager.play_click()

func _on_contrast_toggled(toggled_on: bool) -> void:
	if _is_updating_ui:
		return
	_working_settings["high_contrast"] = toggled_on
	label_contrast_hint.text = "Alto contraste: Activado" if toggled_on else "Alto contraste: Desactivado"
	StateManager.preview_settings(_working_settings)
	AudioManager.play_click()

func _on_reset_pressed() -> void:
	AudioManager.play_click()
	# FA-03.01: Restablecer a valores de fábrica en memoria de trabajo
	_working_settings = StateManager.get_default_settings().duplicate(true)
	_sync_ui_from_working()
	# Previsualizar en tiempo real sin guardar en disco ni cerrar modal
	StateManager.preview_settings(_working_settings)

func _on_cancel_pressed() -> void:
	AudioManager.play_click()
	# FA-05.01: Cancelar - Descartar cambios y revertir a _backup_settings
	StateManager.preview_settings(_backup_settings)
	visible = false

func _on_save_pressed() -> void:
	# FN-05 / FN-06: Guardar cambios en persistencia
	_is_saved = true
	StateManager.save_settings(_working_settings)
	visible = false
	AudioManager.play_success()

func _exit_tree() -> void:
	# FE-01: Cierre inesperado sin guardar
	if visible and not _is_saved and not _backup_settings.is_empty():
		StateManager.preview_settings(_backup_settings)

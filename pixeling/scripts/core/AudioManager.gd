## AudioManager - PixelIng Core
## Generador de efectos de sonido Retro / 8-bit en Godot 4
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico)
extends Node

signal sfx_volume_changed(new_volume: float)
signal music_volume_changed(new_volume: float)

var audio_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var sfx_volume: float = 1.0
var music_volume: float = 1.0
var current_music_path: String = ""

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "SFXPlayer"
	add_child(audio_player)
	
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)

	if has_node("/root/StateManager"):
		var sm = get_node("/root/StateManager")
		if sm.has_method("get_settings"):
			var settings: Dictionary = sm.get_settings()
			sfx_volume = float(settings.get("sfx_volume", 1.0))
			music_volume = float(settings.get("music_volume", 1.0))
	
	set_sfx_volume(sfx_volume)
	set_music_volume(music_volume)

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	if audio_player:
		if sfx_volume <= 0.001:
			audio_player.volume_db = -80.0
		else:
			audio_player.volume_db = linear_to_db(sfx_volume)
	sfx_volume_changed.emit(sfx_volume)

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if music_player:
		if music_volume <= 0.001:
			music_player.volume_db = -80.0
		else:
			music_player.volume_db = linear_to_db(music_volume)
	music_volume_changed.emit(music_volume)

## Reproduce una pista musical en bucle a través del canal MusicPlayer
func play_music(path: String, loop: bool = true) -> void:
	if current_music_path == path and music_player and music_player.playing:
		return
	
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		print("[AudioManager] Pista de música no encontrada: ", path)
		return
	
	var stream = null
	if ResourceLoader.exists(path):
		stream = load(path)
	
	if not stream and FileAccess.file_exists(path):
		if path.ends_with(".mp3"):
			var mp3 := AudioStreamMP3.new()
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				mp3.data = f.get_buffer(f.get_length())
				f.close()
				stream = mp3
	
	if not stream:
		return
	
	if stream is AudioStreamMP3:
		stream.loop = loop
	elif stream is AudioStreamOggVorbis:
		stream.loop = loop
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	
	current_music_path = path
	if music_player:
		music_player.stream = stream
		music_player.play()
		print("[AudioManager] Reproduciendo música de fondo: ", path)

## Detiene la música actual
func stop_music() -> void:
	current_music_path = ""
	if music_player:
		music_player.stop()

## Pausa o reanuda la música
func pause_music(paused: bool = true) -> void:
	if music_player:
		music_player.stream_paused = paused

## Genera un tono de onda cuadrada (8-bit) programáticamente en memoria
func _create_8bit_tone(freq: float, duration: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_frames: int = int(sample_rate * duration)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false

	var data := PackedByteArray()
	data.resize(total_frames)

	for i in range(total_frames):
		var t: float = float(i) / float(sample_rate)
		var val: float = sin(2.0 * PI * freq * t)
		var sample: int = 127 if val >= 0 else -128
		data[i] = sample & 0xFF

	stream.data = data
	return stream

func play_tone(freq: float, duration: float = 0.08) -> void:
	var stream := _create_8bit_tone(freq, duration)
	audio_player.stream = stream
	audio_player.play()

func play_click() -> void:
	play_tone(600.0, 0.04)

func play_sfx(sfx_name: String = "") -> void:
	match sfx_name:
		"success", "win", "victory":
			play_success()
		"error", "fail", "game_over":
			play_game_over()
		_:
			play_click()

func play_step() -> void:
	play_tone(350.0, 0.06)

func play_rotate() -> void:
	play_tone(520.0, 0.08)

func play_error() -> void:
	play_tone(180.0, 0.18)

func play_success() -> void:
	play_tone(587.33, 0.1) # D5
	get_tree().create_timer(0.1).timeout.connect(func():
		play_tone(880.0, 0.2)  # A5
	)

func play_game_over() -> void:
	play_tone(220.0, 0.14)
	get_tree().create_timer(0.14).timeout.connect(func():
		play_tone(174.61, 0.16)
		get_tree().create_timer(0.16).timeout.connect(func():
			play_tone(130.81, 0.28)
		)
	)


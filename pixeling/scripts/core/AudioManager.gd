## AudioManager - PixelIng Core
## Generador de efectos de sonido Retro / 8-bit en Godot 4
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico)
extends Node

var audio_player: AudioStreamPlayer

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

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

func play_step() -> void:
	play_tone(350.0, 0.06)

func play_rotate() -> void:
	play_tone(520.0, 0.08)

func play_error() -> void:
	play_tone(180.0, 0.18)

func play_success() -> void:
	play_tone(587.33, 0.1) # D5
	await get_tree().create_timer(0.1).timeout
	play_tone(880.0, 0.2)  # A5

func play_game_over() -> void:
	play_tone(220.0, 0.14)
	await get_tree().create_timer(0.14).timeout
	play_tone(174.61, 0.16)
	await get_tree().create_timer(0.16).timeout
	play_tone(130.81, 0.28)


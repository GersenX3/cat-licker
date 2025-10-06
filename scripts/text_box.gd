extends MarginContainer

@onready var label: Label = $MarginContainer/Label
@onready var timer = $Timer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var indicator: AnimatedSprite2D = $NinePatchRect/Control/AnimatedSprite2D

# VARIABLES AÑADIDAS
var speech_sfx: AudioStream
var black_font: bool

const MAX_WIDHT = 256

var text = ""
var letter_index = 0

var letter_time = 0.03
var space_time = 0.06
var puctuation_time = 0.2

signal finished_displaying()

func _ready():
	scale = Vector2.ZERO

func display_text(text_to_display: String, speech_sfx_entry: AudioStream):
	text = text_to_display
	label.text = text_to_display
	audio_stream_player_2d.stream = speech_sfx_entry
	
	await resized
	custom_minimum_size.x = min(size.x, MAX_WIDHT)
	
	if size.x > MAX_WIDHT:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		await resized
		await resized
		custom_minimum_size.y = size.y
		
	global_position.x -= size.x / 2
	global_position.y -= size.y +24
	
	
	label.text = ""
	
	pivot_offset = Vector2(size.x/2, size.y)
	
	var tween = get_tree().create_tween()
	tween.tween_property(
		self, "scale", Vector2(1, 1), 0.15
	).set_trans(
		Tween.TRANS_BACK
	)
	
	_display_letter()
	
func display_text_auto(text_to_display: String, speech_sfx_entry: AudioStream):
	text = text_to_display
	label.text = text_to_display
	audio_stream_player_2d.stream = speech_sfx_entry
	
	await resized
	custom_minimum_size.x = min(size.x, MAX_WIDHT)
	
	if size.x > MAX_WIDHT:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		await resized
		await resized
		custom_minimum_size.y = size.y
		
	global_position.x -= size.x / 2
	global_position.y -= size.y +24
	
	
	label.text = ""
	
	pivot_offset = Vector2(size.x/2, size.y)
	
	var tween = get_tree().create_tween()
	tween.tween_property(
		self, "scale", Vector2(1, 1), 0.15
	).set_trans(
		Tween.TRANS_BACK
	)
	
	_display_letter()
	
func _display_letter():
	label.text += text[letter_index]
	
	letter_index += 1
	if letter_index >= text.length():
		finished_displaying.emit()
		if DialogSystem._auto_advance == false:
			indicator.visible = true
		return
	
	match  text[letter_index]:
		"!", ".", ",", "?":
			timer.start(puctuation_time)
		" ":
			timer.start(space_time)
		_:
			timer.start(letter_time)
			
			var new_audio_player = audio_stream_player_2d.duplicate()
			new_audio_player.pitch_scale += randf_range(-0.1, 0.1)
			if text[letter_index] in ["a", "e", "i", "o", "u"]:
				new_audio_player.pitch_scale += 0.2
			add_child(new_audio_player)  # Añadir como hijo para heredar posición
			new_audio_player.global_position = label.global_position  # Asignar la misma posición que label
			new_audio_player.play()
			await new_audio_player.finished
			new_audio_player.queue_free()

func _on_timer_timeout() -> void:
	_display_letter()

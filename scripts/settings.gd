extends Control

@onready var save: Button = $CenterContainer/VBoxContainer/SAVE
@onready var settings: Control = $"."
@onready var crt_button: CheckButton = $CenterContainer/VBoxContainer/CRTButton
@onready var music_slider: HSlider = $CenterContainer/VBoxContainer/MusicSlider
@onready var sfx_slider_2: HSlider = $CenterContainer/VBoxContainer/SFXSlider2

func _ready() -> void:
	# ✅ Cargar valores guardados al abrir el panel
	crt_button.button_pressed = GlobalValues.crt_enabled
	music_slider.value        = GlobalValues.music_volume
	sfx_slider_2.value        = GlobalValues.sfx_volume

func _on_save_pressed() -> void:
	GlobalValues.save_settings(
		crt_button.button_pressed,
		music_slider.value,
		sfx_slider_2.value
	)
	settings.queue_free()

extends Control
@onready var english: Button = $CenterContainer/VBoxContainer/English
@onready var español: Button = $CenterContainer/VBoxContainer/Español
@onready var language: Control = $"."


func _on_english_pressed() -> void:
	EventBus.emit("change_to_english", null)
	language.queue_free()

func _on_español_pressed() -> void:
	EventBus.emit("cambio_a_español", null)
	language.queue_free()

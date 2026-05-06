extends Control

@onready var stock: TextureButton = $HBoxContainer/Stock
@onready var hub: TextureButton = $HBoxContainer/Hub
@onready var store: TextureButton = $HBoxContainer/Store
@onready var camera_2d: Camera2D = $".."

var origin: Vector2

func _ready() -> void:
	origin = camera_2d.position

func _move_camera(target: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(camera_2d, "position", target, 0.4)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN_OUT)

func _on_stock_pressed() -> void:
	_move_camera(origin + Vector2(-384, 0))
	MusicManager.play_sound("res://assets/sfx/pogo.wav", 0.3, false, 1 + randf_range(0,0.3))


func _on_hub_pressed() -> void:
	_move_camera(origin)
	MusicManager.play_sound("res://assets/sfx/pogo.wav", 0.3, false, 1 + randf_range(0,0.3))


func _on_store_pressed() -> void:
	_move_camera(origin + Vector2(384, 0))
	MusicManager.play_sound("res://assets/sfx/pogo.wav", 0.3, false, 1 + randf_range(0,0.3))

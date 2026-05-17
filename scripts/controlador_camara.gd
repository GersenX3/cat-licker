extends Control

@onready var stock: TextureButton = $HBoxContainer/Stock
@onready var hub: TextureButton = $HBoxContainer/Hub
@onready var store: TextureButton = $HBoxContainer/Store
@onready var camera_2d: Camera2D = $".."
@onready var chan: AnimatedSprite2D = $HBoxContainer/chan
@onready var caro: AnimatedSprite2D = $HBoxContainer/caro
@onready var kira: AnimatedSprite2D = $HBoxContainer/kira
var origin: Vector2
var language_scene = preload("res://scenes/language.tscn")
var settings_scene = preload("res://scenes/settings.tscn")

func _ready() -> void:
	EventBus.subscribe("pop_up_chanel", _lanzar_chanel, false)
	EventBus.subscribe("pop_up_caroline", _lanzar_caroline, false)
	EventBus.subscribe("pop_up_kira", _lanzar_kira, false)
	origin = camera_2d.position
	await get_tree().process_frame  # Esperar para que size esté disponible
	_position_at_camera_bottom()

func _position_at_camera_bottom() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var zoom = camera_2d.zoom
	var half_w = (viewport_size.x / 2.0) / zoom.x
	var half_h = (viewport_size.y / 2.0) / zoom.y
	# Centrado horizontalmente, pegado al fondo del viewport
	position = Vector2(-half_w, half_h - size.y)

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

func _lanzar_chanel(_arg) -> void:
	if chan.visible:
		return
	chan.visible = true
	MusicManager.play_sound("res://assets/sfx/Voz.wav", 0.2, false, 1)
	await get_tree().create_timer(1).timeout
	chan.visible = false

func _lanzar_caroline(_arg) -> void:
	if caro.visible:
		return
	caro.visible = true
	MusicManager.play_sound("res://assets/sfx/Voz.wav", 0.2, false, 2)
	await get_tree().create_timer(1).timeout
	caro.visible = false

func _lanzar_kira(_arg) -> void:
	if kira.visible:
		return
	kira.visible = true
	MusicManager.play_sound("res://assets/sfx/Voz.wav", 0.2, false, 0.5)
	await get_tree().create_timer(1).timeout
	kira.visible = false

func _on_language_button_pressed() -> void:
	var instancia = language_scene.instantiate()
	camera_2d.add_child(instancia)

func _on_options_button_pressed() -> void:
	var instancia = settings_scene.instantiate()
	camera_2d.add_child(instancia)

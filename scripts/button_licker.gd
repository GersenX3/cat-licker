extends Button

# Variables del sistema de combo/crescendo
var click_count: int = 0
var last_click_time: float = 0.0
@export var combo_window: float = 1.0
@export var max_combo: int = 10

func _ready() -> void:
	flat = true
	modulate = Color(1, 1, 1, 0) # Invisible

func _process(_delta: float) -> void:
	# Reinicia combo si pasa demasiado tiempo
	if Time.get_ticks_msec() / 1000.0 - last_click_time > combo_window:
		click_count = 0

func _on_pressed() -> void:
	# Emitir un solo evento con el nombre de la animación que debe ejecutarse
	EventBus.emit("despertando", "despertando")  # ← Cambia el string por la anim deseada
	EventBus.emit("lamiendo", "lamiendo")
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_click_time > combo_window:
		click_count = 0

	last_click_time = now
	click_count = min(click_count + 1, max_combo)

	# Calcular bonus y ganancias
	var combo_bonus = Big_Number.from_float(float(click_count))
	var total_gain = GlobalValues.click_value.multiply(combo_bonus)
	GlobalValues.hair_balls_total = GlobalValues.hair_balls_total.add_another_big(total_gain)

	# Efectos sonoros
	var combo_factor = float(click_count) / float(max_combo)
	var pitch = 1.0 + (combo_factor * 0.5)
	var volume = -5.0 + (combo_factor * 5.0)
	MusicManager.play_sound("res://assets/sfx/buble.wav", pitch, true, volume, global_position)

	# Texto flotante
	spawn_floating_text("+" + combo_bonus.to_readable_string(), get_local_mouse_position())

func spawn_floating_text(text: String, pos: Vector2) -> void:
	var main_node = get_node("/root/Main")
	if not main_node:
		return

	var label = Label.new()
	label.text = text
	label.global_position = global_position + pos
	label.z_index = 10
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 1, 0.5))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.label_settings = LabelSettings.new()
	label.label_settings.outline_size = 4
	label.label_settings.outline_color = Color(0, 0, 0)
	main_node.add_child(label)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 80, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(label, "scale", Vector2(1.0, 1.0), 0.7)
	tween.tween_callback(label.queue_free).set_delay(0.8)

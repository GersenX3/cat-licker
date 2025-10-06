extends Button

# Variables para el sistema de crescendo
var click_count: int = 0
var last_click_time: float = 0.0
var combo_window: float = 1.0
var max_combo: int = 10

func _ready() -> void:
	# Hacer el botón invisible pero funcional
	flat = true
	modulate = Color(1, 1, 1, 0)  # Completamente transparente

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() / 1000.0 - last_click_time > combo_window:
		click_count = 0

func _on_pressed() -> void:
	GlobalValues.hair_balls_total = GlobalValues.hair_balls_total.add_another_big(GlobalValues.click_value)
	
	# Actualizar combo
	last_click_time = Time.get_ticks_msec() / 1000.0
	click_count = min(click_count + 1, max_combo)
	
	# Calcular pitch y volumen basado en combo
	var combo_factor = float(click_count) / float(max_combo)
	var pitch = 1.0 + (combo_factor * 0.5)
	var volume = -5.0 + (combo_factor * 5.0)
	
	MusicManager.play_sound("res://assets/sfx/buble.wav", pitch, true, volume, global_position)
	
	# Spawn del label flotante en la posición del click
	spawn_floating_text("+1", get_local_mouse_position())

func spawn_floating_text(text: String, pos: Vector2) -> void:
	# Obtener referencia a Main
	var main_node = get_node("/root/Main")
	if not main_node:
		return
	
	# Crear el label
	var label = Label.new()
	label.text = text
	label.global_position = global_position + pos
	label.z_index = 10
	
	# Configurar estilo del texto
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 1, 0.5))  # Amarillo
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.label_settings = LabelSettings.new()
	label.label_settings.outline_size = 4
	label.label_settings.outline_color = Color(0, 0, 0)
	
	# Agregar a Main
	main_node.add_child(label)
	
	# Animar el label
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Movimiento hacia arriba
	tween.tween_property(label, "global_position:y", label.global_position.y - 80, 0.8).set_ease(Tween.EASE_OUT)
	
	# Fade out
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	
	# Escala (pequeño pop al inicio)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(label, "scale", Vector2(1.0, 1.0), 0.7)
	
	# Eliminar después de la animación
	tween.tween_callback(label.queue_free).set_delay(0.8)

extends RichTextLabel

# Variables para animaciones
var previous_value: Big_Number = Big_Number.new(0, 0)
var scale_tween: Tween
var color_tween: Tween

func _ready() -> void:
	pivot_offset = size / 2  # Centro para escalar desde el medio

	# Suscribirse a la fuente de verdad correspondiente
	if self.name != "total":
		GlobalValues.production_changed.connect(_on_value_changed)
		_on_value_changed(GlobalValues.hairs_balls_per_second)
	else:
		GlobalValues.balance_changed.connect(_on_value_changed)
		_on_value_changed(GlobalValues.hair_balls_total)

func _on_value_changed(current_value: Big_Number) -> void:
	var new_text = "[wave]" + current_value.to_readable_string() + "[/wave]"

	# Detectar si el valor cambió significativamente
	if not current_value.is_equal(previous_value):
		if current_value.is_greater(previous_value):
			animate_value_change()
			pulse_color()
		previous_value = current_value.duplicate_big()

	self.text = new_text

# Animación de escala tipo "pop"
func animate_value_change() -> void:
	# Cancelar tween anterior si existe
	if scale_tween:
		scale_tween.kill()
	
	scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_ELASTIC)
	
	# Efecto de rebote
	scale = Vector2.ONE
	scale_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1)
	scale_tween.tween_property(self, "scale", Vector2.ONE, 0.3)

# Pulso de color
func pulse_color() -> void:
	if color_tween:
		color_tween.kill()
	
	color_tween = create_tween()
	color_tween.set_ease(Tween.EASE_OUT)
	
	# Color dorado/amarillo brillante
	var highlight_color = Color(1.5, 1.5, 0.8, 1.0)
	var normal_color = Color(1.0, 1.0, 1.0, 1.0)
	
	modulate = highlight_color
	color_tween.tween_property(self, "modulate", normal_color, 0.3)

# Agrega esta función para momentos especiales
func celebrate_milestone() -> void:
	var celebration_tween = create_tween()
	celebration_tween.set_parallel(true)
	
	# Rotación ligera
	celebration_tween.tween_property(self, "rotation_degrees", -5, 0.1)
	celebration_tween.chain().tween_property(self, "rotation_degrees", 5, 0.2)
	celebration_tween.chain().tween_property(self, "rotation_degrees", 0, 0.1)
	
	# Escala más dramática
	celebration_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15)
	celebration_tween.chain().tween_property(self, "scale", Vector2.ONE, 0.3)
	
	# Color arcoíris
	var rainbow_colors = [
		Color(1.5, 0.5, 0.5),  # Rojo
		Color(1.5, 1.5, 0.5),  # Amarillo
		Color(0.5, 1.5, 0.5),  # Verde
		Color(0.5, 1.5, 1.5),  # Cyan
	]
	
	for color in rainbow_colors:
		celebration_tween.tween_property(self, "modulate", color, 0.1)
	celebration_tween.tween_property(self, "modulate", Color.WHITE, 0.2)

extends RichTextLabel

# Variables para animaciones
var previous_value: Big_Number = Big_Number.new(0, 0)
var scale_tween: Tween
var color_tween: Tween
var update_timer: float = 0.0
var update_interval: float = 0.05  # Actualizar cada 0.05 segundos

func _ready() -> void:
	pivot_offset = size / 2  # Centro para escalar desde el medio

func _process(_delta: float) -> void:
	update_timer += _delta
	
	# Actualizar solo cada cierto intervalo para performance
	if update_timer < update_interval:
		return
	update_timer = 0.0
	
	var current_value: Big_Number
	var new_text: String
	
	if self.name != "total":
		current_value = GlobalValues.hairs_balls_per_second
		new_text = "[wave]" + current_value.to_readable_string() + "[/wave]"
	else:
		current_value = GlobalValues.hair_balls_total
		new_text = "[wave]" + current_value.to_readable_string() + "[/wave]"
	
	# Detectar si el valor cambió significativamente
	if not current_value.is_equal(previous_value):
		var value_increased = current_value.is_greater(previous_value)
		
		if value_increased:
			# Efecto de "pop" cuando el valor aumenta
			animate_value_change()
			
			# Color pulsante basado en crecimiento
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

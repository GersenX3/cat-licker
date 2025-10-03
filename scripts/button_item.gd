extends Button

@onready var price_label: Label = $Price
@onready var prod_label: Label = $Prod
@onready var owned_label: Label = $Owned
@onready var name_label: Label = $Name

# Propiedades base del item
var item_name: String = "Item"
var description: String = "Descripción del item"
#var icon: Texture2D = null

# Economía (basado en Cookie Clicker)
var base_cost: Big_Number  # Costo inicial
var current_value: Big_Number
var base_production: Big_Number  # BpS (Balls per Second)
var cost_multiplier: float = 1.15  # Factor exponencial (15% como Cookie Clicker)
var store_index: int = 0
var amort_time: Big_Number

# Estado actual
var quantity: int = 0  # Cantidad comprada

# Scroll del nombre
var scroll_container: Control
var scroll_label: Label
var name_scroll_tween: Tween
var max_name_width: float = 240.0
var scroll_speed: float = 50.0  # píxeles por segundo
var scroll_pause: float = 1.0  # pausa en segundos antes de repetir
var original_name_text: String = ""

func _ready() -> void:
	custom_minimum_size = Vector2(344, 64)
	
	# Configurar sistema de scroll
	setup_scroll_system()
	
	update_labels()

func setup_scroll_system() -> void:
	# Guardar el texto original y ocultar el label original
	original_name_text = name_label.text
	
	# Crear contenedor con clip
	scroll_container = Control.new()
	scroll_container.position = name_label.position
	scroll_container.size = Vector2(max_name_width, name_label.size.y)
	scroll_container.clip_contents = true
	
	# Crear label interno que se moverá
	scroll_label = Label.new()
	
	# Copiar TODAS las propiedades de tema del label original
	if name_label.label_settings:
		scroll_label.label_settings = name_label.label_settings
	
	# Copiar theme overrides si existen
	scroll_label.add_theme_font_override("font", name_label.get_theme_font("font"))
	scroll_label.add_theme_font_size_override("font_size", name_label.get_theme_font_size("font_size"))
	scroll_label.add_theme_color_override("font_color", name_label.get_theme_color("font_color"))
	
	# Copiar otras propiedades visuales
	scroll_label.horizontal_alignment = name_label.horizontal_alignment
	scroll_label.vertical_alignment = name_label.vertical_alignment
	
	# Agregar a la jerarquía
	name_label.get_parent().add_child(scroll_container)
	scroll_container.add_child(scroll_label)
	
	# Ocultar el label original
	name_label.visible = false

func _on_pressed() -> void:
	print(self.text)
	if Store.purchase_item(self.store_index):
		# Actualizar labels después de la compra
		quantity += 1
		update_labels()

# Función para actualizar todos los labels
func update_labels() -> void:
	scroll_label.text = str(self.name)
	price_label.text = "$" + str(calculate_current_cost().to_readable_string())
	prod_label.text = str(base_production.to_readable_string()) + "B/S"
	owned_label.text = str(quantity)
	
	# Verificar si necesita scroll después de actualizar el texto
	check_name_scroll()

# Calcular el costo actual basado en la cantidad comprada
func calculate_current_cost() -> Big_Number:
	# Fórmula: base_cost * (cost_multiplier ^ quantity)
	return base_cost.multiply(Big_Number.new(pow(cost_multiplier, quantity)))

# Verificar si el nombre necesita scroll
func check_name_scroll() -> void:
	# Esperar un frame para que el label se actualice
	await get_tree().process_frame
	
	# Obtener el ancho real del texto
	var font = scroll_label.get_theme_font("font")
	var font_size = scroll_label.get_theme_font_size("font_size")
	var text_width = font.get_string_size(scroll_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	# Si el texto excede el ancho máximo, iniciar scroll
	if text_width > max_name_width:
		start_name_scroll(text_width)
	else:
		stop_name_scroll()
		scroll_label.position.x = 0

# Iniciar animación de scroll
func start_name_scroll(text_width: float) -> void:
	# Detener animación anterior si existe
	stop_name_scroll()
	
	# Calcular cuántas copias necesitamos (al menos 3 para cubrir el espacio)
	var copies_needed = ceil(max_name_width / text_width) + 2
	
	# Crear texto multiplicado con separador
	var original_text = scroll_label.text
	var multiplied_text = ""
	for i in range(copies_needed):
		multiplied_text += original_text
		if i < copies_needed - 1:
			multiplied_text += "   •   "
	
	scroll_label.text = multiplied_text
	
	# Calcular duración basada en velocidad
	var scroll_distance = text_width + 60  # +40 por el separador "   •   "
	var duration = scroll_distance / scroll_speed
	
	# Resetear posición
	scroll_label.position.x = 0
	
	# Crear tween
	name_scroll_tween = create_tween()
	name_scroll_tween.set_loops()  # Loop infinito
	
	# Animar posición horizontal del label interno
	name_scroll_tween.tween_property(scroll_label, "position:x", -scroll_distance, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	name_scroll_tween.tween_property(scroll_label, "position:x", 0, 0)  # Reset instantáneo
	name_scroll_tween.tween_interval(scroll_pause)  # Pausa antes de repetir

# Detener animación de scroll
func stop_name_scroll() -> void:
	if name_scroll_tween:
		name_scroll_tween.kill()
		name_scroll_tween = null
	
	# Restaurar texto original sin multiplicar
	scroll_label.text = str(self.name)
	scroll_label.position.x = 0

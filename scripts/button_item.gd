extends Button

@onready var price_label: Label = $Price
@onready var prod_label: Label = $Prod
@onready var owned_label: Label = $Owned
@onready var name_label: Label = $Name


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

# Estados del botón
enum ButtonState {
	HIDDEN,      # No visible aún (< 1/4 del costo)
	GHOST,       # Silueta (>= 1/4 del costo)
	LOCKED,      # Completo pero disabled (>= 1/2 del costo)
	UNLOCKED     # Desbloqueado y funcional
}

var current_state: ButtonState = ButtonState.HIDDEN
var has_been_unlocked: bool = false  # Si ya alcanzó el estado UNLOCKED alguna vez

func _ready() -> void:
	custom_minimum_size = Vector2(344, 64)
	
	# ✅ SINCRONIZAR CANTIDAD CON STORE
	if Store and Store.store_items.size() > store_index:
		var store_item = Store.store_items[store_index]
		quantity = store_item.quantity
		print("🔄 Synced quantity for ", item_name, ": ", quantity)
	
	# Configurar sistema de scroll
	setup_scroll_system()
	
	update_labels()
	update_button_state()


func _process(_delta: float) -> void:
	# Actualizar estado del botón constantemente
	update_button_state()

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
	#Create animation with icon
	MusicManager.play_sound("res://assets/sfx/bounce.wav", 2, true, 1, self.global_position)
	EventBus.emit("buy", {"item": item_name, "quantity": quantity})
	# Solo permitir compra si está desbloqueado
	if current_state != ButtonState.UNLOCKED:
		return
	
	print(self.text)
	if Store.purchase_item(self.store_index):
		# Actualizar labels después de la compra
		quantity += 1
		update_labels()
		# Animar el botón
		shake_button()
		# Crear animación del icono (puedes ajustar el offset X aquí)
		spawn_icon_animation(-137)
		translation_animation(Vector2(768-16, 576), Vector2(384+16, 576), 2)  # 0 = centro, valores negativos = izquierda, positivos = derecha

# Crear y animar el icono flotante
func spawn_icon_animation(x_offset: float = 0.0) -> void:
	# Verificar que existe un icono
	if not icon:
		return
	
	# Obtener referencia a Main
	var main_node = get_node("/root/Main")
	if not main_node:
		push_error("No se encontró el nodo Main")
		return
	
	# Crear el Sprite2D
	var icon_sprite = Sprite2D.new()
	icon_sprite.texture = icon
	icon_sprite.z_index = 0
	# Aplicar offset X a la posición
	icon_sprite.global_position = global_position + Vector2(size.x / 2 + x_offset, size.y / 2)
	
	# Ajustar escala si el icono es muy grande
	icon_sprite.scale = Vector2(1, 1)
	
	# Agregar a Main
	main_node.add_child(icon_sprite)
	
	# Crear animación con Tween
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Rotación de izquierda a derecha (balanceo)
	tween.tween_property(icon_sprite, "rotation_degrees", -15, 0.15)
	tween.chain().tween_property(icon_sprite, "rotation_degrees", 15, 0.3)
	tween.chain().tween_property(icon_sprite, "rotation_degrees", -10, 0.2)
	tween.chain().tween_property(icon_sprite, "rotation_degrees", 0, 0.15)
	
	# Movimiento hacia arriba
	tween.tween_property(icon_sprite, "global_position:y", icon_sprite.global_position.y - 100, 0.8).set_ease(Tween.EASE_OUT)
	
	# Fade out (desaparecer)
	tween.tween_property(icon_sprite, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	
	# Escala (crecer un poco al principio)
	tween.tween_property(icon_sprite, "scale", Vector2(0.7, 0.7), 0.2).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(icon_sprite, "scale", Vector2(0.4, 0.4), 0.6)
	
	# Eliminar el sprite cuando termine la animación
	tween.tween_callback(icon_sprite.queue_free).set_delay(0.8)

# Animación de traslación entre dos puntos
# Función modificada
func translation_animation(from_pos: Vector2, to_pos: Vector2, duration: float = 0.8) -> void:
	# Verificar que existe un icono
	if not icon:
		return
	
	# Obtener referencia a Main
	var main_node = get_node("/root/Main")
	if not main_node:
		push_error("No se encontró el nodo Main")
		return
	
	# Crear el Sprite2D
	var icon_sprite = Sprite2D.new()
	icon_sprite.texture = icon
	icon_sprite.z_index = 0
	icon_sprite.global_position = from_pos
	
	# Ajustar escala
	icon_sprite.scale = Vector2(1, 1)
	
	# Agregar a Main
	main_node.add_child(icon_sprite)
	
	# Crear animación de movimiento
	var move_tween = create_tween()
	move_tween.tween_property(icon_sprite, "global_position", to_pos, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	
	# Crear animación de rotación continua (separada)
	var rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(icon_sprite, "rotation_degrees", -15, 0.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	rotation_tween.tween_property(icon_sprite, "rotation_degrees", 15, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	rotation_tween.tween_property(icon_sprite, "rotation_degrees", 0, 0.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	# Al terminar la animación, agregar al VBoxContainer
	move_tween.tween_callback(func():
		rotation_tween.kill()
		icon_sprite.rotation_degrees = 0
		
		# Obtener referencia al VBoxContainer del inventario
		var inventory_container = get_node_or_null("/root/Main/UI/Inventory/ScrollContainer/StoreContainerIntentory")
		if inventory_container and inventory_container.has_method("add_icon"):
			# Reparentar el icono al VBoxContainer
			icon_sprite.get_parent().remove_child(icon_sprite)
			inventory_container.call("add_icon", icon_sprite)
			EventBus.emit("llegada", {"item": "", "quantity": ""})
	).set_delay(0)

func shake_button() -> void:
	var tween = create_tween()
	var original_scale = Vector2(1, 1)  # Escala base fija
	
	# Efecto de "rebote" al hacer click
	tween.tween_property(self, "scale", original_scale * 1.1, 0.05)
	tween.tween_property(self, "scale", original_scale * 0.95, 0.05)
	tween.tween_property(self, "scale", original_scale * 1.05, 0.05)
	tween.tween_property(self, "scale", original_scale, 0.05)

# Función para actualizar todos los labels
func update_labels() -> void:
	scroll_label.text = str(self.name)
	price_label.text = "$ " + str(calculate_current_cost().to_readable_string())
	prod_label.text = str(base_production.to_readable_string()) + " b/s"
	owned_label.text = str(quantity)
	
	# Verificar si necesita scroll después de actualizar el texto
	check_name_scroll()

# Calcular el costo actual basado en la cantidad comprada
func calculate_current_cost() -> Big_Number:
	# Fórmula: base_cost * (cost_multiplier ^ quantity)
	return base_cost.multiply(Big_Number.new(pow(cost_multiplier, quantity)))

# Actualizar el estado visual del botón
# Actualizar el estado visual del botón
func update_button_state() -> void:
	var current_balance = GlobalValues.hair_balls_total
	var cost = calculate_current_cost()
	
	# Si ya fue desbloqueado, solo alternar entre LOCKED y UNLOCKED
	if has_been_unlocked:
		if current_balance.is_greater_or_equal(cost):
			current_state = ButtonState.UNLOCKED
		else:
			current_state = ButtonState.LOCKED
		apply_visual_state()
		return
	
	# Calcular umbrales solo si no ha sido desbloqueado
	var quarter_cost = cost.multiply(Big_Number.new(0.25, 0))
	var half_cost = cost.multiply(Big_Number.new(0.5, 0))
	
	var new_state: ButtonState
	
	# Determinar nuevo estado
	if current_balance.is_less(quarter_cost):
		new_state = ButtonState.HIDDEN
	elif current_balance.is_less(half_cost):
		new_state = ButtonState.GHOST
	elif current_balance.is_less(cost):
		new_state = ButtonState.LOCKED
		has_been_unlocked = true  # Marcar como desbloqueado
	else:
		new_state = ButtonState.UNLOCKED
		has_been_unlocked = true  # Marcar como desbloqueado
	
	# Aplicar cambios visuales solo si el estado cambió
	if new_state != current_state:
		current_state = new_state
		apply_visual_state()

# Aplicar el estado visual correspondiente
func apply_visual_state() -> void:
	match current_state:
		ButtonState.HIDDEN:
			visible = false
		
		ButtonState.GHOST:
			visible = true
			disabled = true
			modulate = Color(1, 1, 1, 0.3)  # Muy transparente
			
			# Ocultar labels
			price_label.visible = false
			prod_label.visible = false
			owned_label.visible = false
			scroll_container.visible = false
		
		ButtonState.LOCKED:
			visible = true
			disabled = true
			modulate = Color(0.7, 0.7, 0.7, 1.0)  # Ligeramente oscurecido
			
			# Mostrar labels
			price_label.visible = true
			prod_label.visible = true
			owned_label.visible = true
			scroll_container.visible = true
		
		ButtonState.UNLOCKED:
			visible = true
			disabled = false
			modulate = Color(1, 1, 1, 1)  # Color normal
			
			# Mostrar labels
			price_label.visible = true
			prod_label.visible = true
			owned_label.visible = true
			scroll_container.visible = true

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
	var scroll_distance = text_width + 60
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

# Verificar si debe ser visible (llamado desde Store)
func should_be_visible() -> bool:
	var current_balance = GlobalValues.hair_balls_total
	var cost = calculate_current_cost()
	var quarter_cost = cost.multiply(Big_Number.new(0.25, 0))
	
	return current_balance.is_greater_or_equal(quarter_cost) or has_been_unlocked

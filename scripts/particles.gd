extends CPUParticles2D

# Referencia al contenedor de inventario
@export var inventory_container: VBoxContainer


# Texturas de los iconos recolectados
var icon_textures: Array[Texture2D] = []

# Índice actual para rotación de texturas
var current_texture_index: int = 0

func _ready() -> void:
	# Configuración inicial de partículas
	setup_particles()
	
	# Conectar señales del inventario si es necesario
	if inventory_container:
		# Iniciamos con las texturas actuales
		update_particle_textures()

func setup_particles() -> void:
	# Configuración base de partículas
	emitting = true
	amount = 20
	lifetime = 2.0
	one_shot = false
	explosiveness = 0.0
	randomness = 0.5
	
	# Dirección y velocidad
	direction = Vector2(0, -1)
	spread = 45.0
	gravity = Vector2(0, 98)
	initial_velocity_min = 0
	initial_velocity_max = 0.0
	
	# Escala
	scale_amount_min = 0.5
	scale_amount_max = 1.0
	scale_amount_curve = create_scale_curve()
	
	# Color y transparencia
	color = Color(1, 1, 1, 1)
	color_ramp = create_color_ramp()
	
	# Rotación
	angular_velocity_min = -180
	angular_velocity_max = 180

func create_scale_curve() -> Curve:
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(0.5, 1.2))
	curve.add_point(Vector2(1, 0))
	return curve

func create_color_ramp() -> Gradient:
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	return gradient

func update_particle_textures() -> void:
	if not inventory_container:
		return
	
	# Limpiar array de texturas
	icon_textures.clear()
	
	# Obtener texturas de los iconos del inventario
	for icon in inventory_container.collected_icons:
		if icon and is_instance_valid(icon) and icon.texture:
			icon_textures.append(icon.texture)
	
	# Si hay texturas, actualizar la textura de partículas
	if icon_textures.size() > 0:
		# Usar la primera textura o rotar entre ellas
		texture = icon_textures[0]
		print("Partículas actualizadas con ", icon_textures.size(), " texturas diferentes")
	else:
		print("No hay texturas disponibles en el inventario")

# Método para actualizar cuando se agrega un nuevo icono
func on_icon_added(new_icon: Sprite2D) -> void:
	if new_icon and new_icon.texture:
		icon_textures.append(new_icon.texture)
		# Actualizar la textura actual de las partículas
		if icon_textures.size() == 1:
			texture = new_icon.texture
		print("Nueva textura agregada a partículas. Total: ", icon_textures.size())

# Proceso para rotar entre texturas (opcional)
func _process(delta: float) -> void:
	# Si quieres que las partículas cambien de textura periódicamente
	if icon_textures.size() > 1:
		rotate_particle_texture()

var time_accumulator: float = 0.0
var texture_change_interval: float = 0.5  # Cambiar cada 0.5 segundos

func rotate_particle_texture() -> void:
	time_accumulator += get_process_delta_time()
	
	if time_accumulator >= texture_change_interval:
		time_accumulator = 0.0
		current_texture_index = (current_texture_index + 1) % icon_textures.size()
		texture = icon_textures[current_texture_index]

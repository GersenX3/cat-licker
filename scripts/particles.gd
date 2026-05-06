extends Node2D

# Referencia al contenedor de inventario
@export var inventory_container: VBoxContainer

# Array de sistemas de partículas individuales
var particle_systems: Array[CPUParticles2D] = []

func _ready() -> void:
	if inventory_container:
		# Esperar a que el inventario cargue primero
		await get_tree().process_frame
		update_particle_textures()

func create_particle_system(icon_texture: Texture2D) -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	
	# Configuración base de partículas (basada en tus ajustes)
	particles.emitting = true
	particles.amount = 1  # 1 partícula por icono
	particles.lifetime = randf_range(3, 4)
	particles.one_shot = false
	particles.explosiveness = 0
	particles.randomness = 1
	# Forma de emisión
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(180, 1)
	# Dirección y velocidad
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.gravity = Vector2(0, randf_range(50, 150))
	particles.initial_velocity_min = 0
	particles.initial_velocity_max = 0.0
	
	# Escala
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.0
	particles.scale_amount_curve = create_scale_curve()
	
	# Color y transparencia
	particles.color = Color(1, 1, 1, 1)
	particles.color_ramp = create_color_ramp()
	
	# Rotación
	particles.angular_velocity_min = -180
	particles.angular_velocity_max = 180
	
	# Asignar textura específica
	particles.texture = icon_texture
	
	return particles

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
		print("⚠️ Inventory container not found")
		return
	
	# Limpiar sistemas de partículas existentes
	for ps in particle_systems:
		if is_instance_valid(ps):
			ps.queue_free()
	particle_systems.clear()
	
	# Crear un sistema de partículas por cada icono
	for icon in inventory_container.collected_icons:
		if icon and is_instance_valid(icon) and icon.texture:
			var particle_system = create_particle_system(icon.texture)
			add_child(particle_system)
			particle_systems.append(particle_system)
	
	print("✨ Sistemas de partículas creados: ", particle_systems.size())

# Método para actualizar cuando se agrega un nuevo icono
func on_icon_added(new_icon: Sprite2D) -> void:
	if new_icon and new_icon.texture:
		var particle_system = create_particle_system(new_icon.texture)
		add_child(particle_system)
		particle_systems.append(particle_system)
		print("✨ Nueva partícula agregada. Total: ", particle_systems.size())

# ====================================================================
# 💾 SISTEMA DE GUARDADO/CARGA DE PARTÍCULAS
# ====================================================================

# ✅ NUEVA FUNCIÓN: Obtener datos para guardar
func get_save_data() -> Array:
	var save_array = []
	
	for ps in particle_systems:
		if is_instance_valid(ps) and ps.texture:
			save_array.append({
				"texture_path": ps.texture.resource_path,
				"emitting": ps.emitting
			})
	
	print("💾 Saving ", save_array.size(), " particle systems")
	return save_array

# ✅ NUEVA FUNCIÓN: Cargar datos guardados
func load_save_data(save_array: Array) -> void:
	print("💾 Loading particle systems: ", save_array.size())
	
	# Limpiar sistemas existentes
	for ps in particle_systems:
		if is_instance_valid(ps):
			ps.queue_free()
	particle_systems.clear()
	
	# Recrear sistemas de partículas desde los datos guardados
	for ps_data in save_array:
		if ps_data.has("texture_path"):
			var texture = load(ps_data["texture_path"]) as Texture2D
			if texture:
				var particle_system = create_particle_system(texture)
				
				# Restaurar estado de emisión
				if ps_data.has("emitting"):
					particle_system.emitting = ps_data["emitting"]
				
				add_child(particle_system)
				particle_systems.append(particle_system)
	
	print("✅ Particle systems loaded: ", particle_systems.size())

# ✅ NUEVA FUNCIÓN: Sincronizar con inventario después de cargar
func sync_with_inventory() -> void:
	if not inventory_container:
		return
	
	# Esperar un frame para asegurar que el inventario esté listo
	await get_tree().process_frame
	
	# Actualizar partículas basándose en los iconos actuales
	update_particle_textures()

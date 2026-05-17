extends Node2D

@export var inventory_container: VBoxContainer
@onready var camera_2d: Camera2D = $".."

var particle_systems: Array[CPUParticles2D] = []

func _ready() -> void:
	_update_position_above_camera()
	if inventory_container:
		await get_tree().process_frame
		update_particle_textures()

func _update_position_above_camera() -> void:
	if not camera_2d:
		return
	
	var viewport_size = get_viewport().get_visible_rect().size
	var zoom = camera_2d.zoom
	var camera_top = camera_2d.global_position.y - (viewport_size.y / 2.0) / zoom.y
	
	global_position = Vector2(camera_2d.global_position.x, camera_top - 20.0)

func create_particle_system(icon_texture: Texture2D) -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	
	particles.emitting = true
	particles.amount = 1
	particles.lifetime = randf_range(3, 4)
	particles.one_shot = false
	particles.explosiveness = 0
	particles.randomness = 1
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(180, 1)
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.gravity = Vector2(0, randf_range(50, 150))
	particles.initial_velocity_min = 0
	particles.initial_velocity_max = 0.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.0
	particles.scale_amount_curve = create_scale_curve()
	particles.color = Color(1, 1, 1, 1)
	particles.color_ramp = create_color_ramp()
	particles.angular_velocity_min = -180
	particles.angular_velocity_max = 180
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
	
	for ps in particle_systems:
		if is_instance_valid(ps):
			ps.queue_free()
	particle_systems.clear()
	
	for icon in inventory_container.collected_icons:
		if icon and is_instance_valid(icon) and icon.texture:
			var particle_system = create_particle_system(icon.texture)
			add_child(particle_system)
			particle_systems.append(particle_system)
	
	print("✨ Sistemas de partículas creados: ", particle_systems.size())

func on_icon_added(new_icon: Sprite2D) -> void:
	if new_icon and new_icon.texture:
		var particle_system = create_particle_system(new_icon.texture)
		add_child(particle_system)
		particle_systems.append(particle_system)
		print("✨ Nueva partícula agregada. Total: ", particle_systems.size())

# ====================================================================
# 💾 SISTEMA DE GUARDADO/CARGA DE PARTÍCULAS
# ====================================================================

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

func load_save_data(save_array: Array) -> void:
	print("💾 Loading particle systems: ", save_array.size())
	
	for ps in particle_systems:
		if is_instance_valid(ps):
			ps.queue_free()
	particle_systems.clear()
	
	for ps_data in save_array:
		if ps_data.has("texture_path"):
			var texture = load(ps_data["texture_path"]) as Texture2D
			if texture:
				var particle_system = create_particle_system(texture)
				if ps_data.has("emitting"):
					particle_system.emitting = ps_data["emitting"]
				add_child(particle_system)
				particle_systems.append(particle_system)
	
	print("✅ Particle systems loaded: ", particle_systems.size())

func sync_with_inventory() -> void:
	if not inventory_container:
		return
	
	await get_tree().process_frame
	update_particle_textures()

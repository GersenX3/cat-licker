extends VBoxContainer

@export var collected_icons: Array[Sprite2D] = []
@export var icon_spacing: float = 10.0
@export var icons_per_row: int = 4
@export var icon_size: float = 64.0
@export var offset_x: float = 10.0
@export var offset_y: float = 10.0
@export var enable_rotation: bool = true
@export var particle_system: Node2D

func _ready() -> void:
	custom_minimum_size = Vector2(352, 100)
	mouse_filter = Control.MOUSE_FILTER_STOP

# ─────────────────────────────────────────────
# AGREGAR ÍCONO
# ─────────────────────────────────────────────

func add_icon(icon_sprite: Sprite2D, item_path: String = "") -> void:
	collected_icons.append(icon_sprite)
	icon_sprite.z_index = 9
	add_child(icon_sprite)
	icon_sprite.scale = Vector2(1, 1)

	if item_path != "":
		icon_sprite.set_meta("item_path", item_path)

	organize_icons()
	update_container_size()

	if enable_rotation:
		animate_icon_rotation(icon_sprite)

	if particle_system and particle_system.has_method("on_icon_added"):
		particle_system.on_icon_added(icon_sprite)

# ─────────────────────────────────────────────
# DETECCIÓN DE CLICK
# ─────────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if not (event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var clicked_index = get_icon_index_at(event.position)

	if clicked_index == -1:
		return

	var icon = collected_icons[clicked_index]
	var item_path = icon.get_meta("item_path", "")

	if item_path == "":
		return

	var group = flood_fill(clicked_index, item_path)

	if group.size() < 2:
		return

	explode_group(group, item_path, event.position)

func get_icon_index_at(pos: Vector2) -> int:
	for i in range(collected_icons.size()):
		if not is_instance_valid(collected_icons[i]):
			continue
		var icon_pos = collected_icons[i].position
		var half = icon_size / 2.0
		var rect = Rect2(icon_pos - Vector2(half, half), Vector2(icon_size, icon_size))
		if rect.has_point(pos):
			return i
	return -1

# ─────────────────────────────────────────────
# FLOOD FILL
# ─────────────────────────────────────────────

func flood_fill(start_index: int, item_path: String) -> Array:
	var visited: Array = []
	var queue: Array = [start_index]

	while queue.size() > 0:
		var current = queue.pop_front()
		if visited.has(current):
			continue
		if not is_instance_valid(collected_icons[current]):
			continue
		if collected_icons[current].get_meta("item_path", "") != item_path:
			continue

		visited.append(current)

		var row = current / icons_per_row
		var col = current % icons_per_row

		var up = current - icons_per_row
		if up >= 0 and not visited.has(up):
			queue.append(up)

		var down = current + icons_per_row
		if down < collected_icons.size() and not visited.has(down):
			queue.append(down)

		if col > 0:
			var left = current - 1
			if not visited.has(left):
				queue.append(left)

		if col < icons_per_row - 1:
			var right = current + 1
			if right < collected_icons.size() and not visited.has(right):
				queue.append(right)

	return visited

# ─────────────────────────────────────────────
# EXPLOSIÓN
# ─────────────────────────────────────────────

func explode_group(indices: Array, item_path: String, click_pos: Vector2) -> void:
	var total_payout = calculate_payout(item_path, indices.size())
	var per_icon_value = total_payout.divide(Big_Number.from_float(float(indices.size())))

	var icons_to_explode: Array[Sprite2D] = []
	for i in indices:
		icons_to_explode.append(collected_icons[i])

	spawn_shockwave(click_pos)
	var pitch = 1.2 - (indices.size() * 0.03)
	MusicManager.play_sound("res://assets/sfx/dash.wav", 0.6, false, pitch)

	for icon in icons_to_explode:
		collected_icons.erase(icon)

	var max_dist = 0.01
	for icon in icons_to_explode:
		max_dist = max(max_dist, icon.position.distance_to(click_pos))

	for icon in icons_to_explode:
		if icon.has_meta("rotation_tween"):
			var rt = icon.get_meta("rotation_tween")
			if rt: rt.kill()

		var dist = icon.position.distance_to(click_pos)
		var delay = (dist / max_dist) * 0.2

		var direction = (icon.position - click_pos).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()

		spawn_floating_text_delayed("+" + per_icon_value.to_readable_string(), icon.global_position, delay)

		var tween = create_tween()
		tween.tween_interval(delay)
		tween.tween_property(icon, "scale", Vector2(1.8, 1.8), 0.12)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.parallel().tween_property(icon, "position", icon.position + direction * 50, 0.2)\
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(icon, "modulate:a", 0.0, 0.18)\
			.set_ease(Tween.EASE_IN)
		tween.tween_callback(icon.queue_free)

	await get_tree().create_timer(0.55).timeout
	organize_icons_animated()
	update_container_size()

# ─────────────────────────────────────────────
# TEXTO FLOTANTE
# ─────────────────────────────────────────────

func spawn_floating_text_delayed(text: String, world_pos: Vector2, delay: float) -> void:
	var main_node = get_node_or_null("/root/Main")
	if not main_node:
		return

	var label = Label.new()
	label.text = text
	label.global_position = world_pos
	label.z_index = 10
	label.modulate.a = 0.0
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	label.label_settings = LabelSettings.new()
	label.label_settings.outline_size = 4
	label.label_settings.outline_color = Color(0, 0, 0)
	main_node.add_child(label)

	var tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(label, "modulate:a", 1.0, 0.05)
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", world_pos.y - 70, 0.7).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.1).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(label, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free).set_delay(0.7)

# ─────────────────────────────────────────────
# ONDA EXPANSIVA
# ─────────────────────────────────────────────

func spawn_shockwave(pos: Vector2) -> void:
	for i in range(3):
		var ring = Panel.new()
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_color = Color(1.0, 0.85, 0.2, 0.9 - i * 0.25)
		style.set_border_width_all(4 - i)
		style.corner_radius_top_left = 200
		style.corner_radius_top_right = 200
		style.corner_radius_bottom_left = 200
		style.corner_radius_bottom_right = 200
		ring.add_theme_stylebox_override("panel", style)

		var start_size = Vector2(10, 10)
		ring.size = start_size
		ring.position = pos - start_size / 2.0
		add_child(ring)

		var delay = i * 0.07
		var end_size = Vector2(140, 140)

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_interval(delay)
		tween.tween_property(ring, "size", end_size, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		tween.tween_property(ring, "position", pos - end_size / 2.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		tween.tween_property(ring, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(ring.queue_free)

# ─────────────────────────────────────────────
# REORGANIZACIÓN ANIMADA
# ─────────────────────────────────────────────

func organize_icons_animated() -> void:
	MusicManager.play_sound("res://assets/sfx/fast_move.wav", 1.0, true, 0.3, global_position)
	for i in range(collected_icons.size()):
		if not is_instance_valid(collected_icons[i]):
			continue
		var row: int = int(i / float(icons_per_row))
		var col = i % icons_per_row
		var target = Vector2(
			offset_x + (col * (icon_size + icon_spacing)),
			offset_y + (row * (icon_size + icon_spacing))
		)
		var delay = i * 0.03
		var tween = create_tween()
		tween.tween_interval(delay)
		tween.tween_property(collected_icons[i], "position", target, 0.35)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	EventBus.emit("pop_up_caroline", null)
	

# ─────────────────────────────────────────────
# PAGO
# ─────────────────────────────────────────────

func calculate_payout(item_path: String, count: int) -> Big_Number:
	var resource = load(item_path)
	if not resource:
		print("❌ No se pudo cargar el recurso: ", item_path)
		return Big_Number.new(0, 0)

	var base_cost = resource.base_cost
	var multiplier = Big_Number.from_float(float(count * count))
	var payout = base_cost.multiply(multiplier)

	print("💥 Explosión de ", count, " ítems — ", resource.item_name)
	print("💰 Payout: ", payout.to_readable_string())

	GlobalValues.hair_balls_total = GlobalValues.hair_balls_total.add_another_big(payout)
	print("💰 Nuevo total: ", GlobalValues.hair_balls_total.to_readable_string())
	return payout

# ─────────────────────────────────────────────
# ORGANIZACIÓN Y TAMAÑO
# ─────────────────────────────────────────────

func animate_icon_rotation(icon_sprite: Sprite2D) -> void:
	const ANIMATION_TIME = 3
	const STEP_1_DURATION = ANIMATION_TIME * 0.25
	const STEP_2_DURATION = ANIMATION_TIME * 0.5
	const STEP_3_DURATION = ANIMATION_TIME * 0.25

	var rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(icon_sprite, "rotation_degrees", -15, STEP_1_DURATION).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	rotation_tween.tween_property(icon_sprite, "rotation_degrees", 15, STEP_2_DURATION).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	rotation_tween.tween_property(icon_sprite, "rotation_degrees", 0, STEP_3_DURATION).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	icon_sprite.set_meta("rotation_tween", rotation_tween)

func organize_icons() -> void:
	for i in range(collected_icons.size()):
		if collected_icons[i] and is_instance_valid(collected_icons[i]):
			var row: int = int(i / float(icons_per_row))
			var col = i % icons_per_row
			collected_icons[i].position = Vector2(
				offset_x + (col * (icon_size + icon_spacing)),
				offset_y + (row * (icon_size + icon_spacing))
			)

func update_container_size() -> void:
	var total_rows: int = int(ceil(collected_icons.size() / float(icons_per_row)))
	var required_height = offset_y + (total_rows * (icon_size + icon_spacing)) + offset_y
	custom_minimum_size.y = required_height

func cleanup_invalid_icons() -> void:
	collected_icons = collected_icons.filter(func(icon): return is_instance_valid(icon))

# ─────────────────────────────────────────────
# GUARDADO
# ─────────────────────────────────────────────

func get_save_data() -> Array:
	var save_array = []
	for icon in collected_icons:
		if is_instance_valid(icon) and icon.texture:
			save_array.append({
				"texture_path": icon.texture.resource_path,
				"item_path": icon.get_meta("item_path", ""),
				"position": { "x": icon.position.x, "y": icon.position.y },
				"scale": { "x": icon.scale.x, "y": icon.scale.y }
			})
	return save_array

func load_save_data(save_array: Array) -> void:
	for icon in collected_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	collected_icons.clear()

	for icon_data in save_array:
		if icon_data.has("texture_path"):
			var texture = load(icon_data["texture_path"]) as Texture2D
			if texture:
				var icon_sprite = Sprite2D.new()
				icon_sprite.texture = texture
				icon_sprite.z_index = 9

				if icon_data.has("item_path") and icon_data["item_path"] != "":
					icon_sprite.set_meta("item_path", icon_data["item_path"])

				if icon_data.has("scale"):
					icon_sprite.scale = Vector2(icon_data["scale"]["x"], icon_data["scale"]["y"])

				collected_icons.append(icon_sprite)
				add_child(icon_sprite)

				if enable_rotation:
					animate_icon_rotation(icon_sprite)

	organize_icons()
	update_container_size()

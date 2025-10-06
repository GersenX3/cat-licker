extends VBoxContainer

@export var collected_icons: Array[Sprite2D] = []
@export var icon_spacing: float = 10.0
@export var icons_per_row: int = 4
@export var icon_size: float = 64.0
@export var offset_x: float = 10.0  # Offset horizontal
@export var offset_y: float = 10.0  # Offset vertical

func _ready() -> void:
	custom_minimum_size = Vector2(352, 100)
	debug_container_properties()

func add_icon(icon_sprite: Sprite2D) -> void:
	collected_icons.append(icon_sprite)
	icon_sprite.z_index = 9
	add_child(icon_sprite)
	icon_sprite.scale = Vector2(1, 1)
	
	organize_icons()
	update_container_size()
	
	print("Icon added! Total icons: ", collected_icons.size())
	debug_container_properties()

func organize_icons() -> void:
	for i in range(collected_icons.size()):
		if collected_icons[i] and is_instance_valid(collected_icons[i]):
			var row: int = int(i / float(icons_per_row))
			var col = i % icons_per_row
			
			# Aplicar offset personalizable
			var x_pos = offset_x + (col * (icon_size + icon_spacing))
			var y_pos = offset_y + (row * (icon_size + icon_spacing))
			
			collected_icons[i].position = Vector2(x_pos, y_pos)
			print("Icon[", i, "] positioned at: ", collected_icons[i].position)

func update_container_size() -> void:
	var total_rows: int = int(ceil(collected_icons.size() / float(icons_per_row)))
	var required_height = offset_y + (total_rows * (icon_size + icon_spacing)) + offset_y
	
	custom_minimum_size.y = required_height
	print("Container height updated to: ", required_height)

func cleanup_invalid_icons() -> void:
	collected_icons = collected_icons.filter(func(icon): return is_instance_valid(icon))

func debug_container_properties() -> void:
	print("\n========== VBOXCONTAINER DEBUG ==========")
	print("VBoxContainer Name: ", name)
	print("Position: ", position)
	print("Global Position: ", global_position)
	print("Size: ", size)
	print("Custom Minimum Size: ", custom_minimum_size)
	print("Total Icons: ", collected_icons.size())
	
	var parent = get_parent()
	if parent and parent is ScrollContainer:
		print("\n========== SCROLL CONTAINER DEBUG ==========")
		print("Parent Size: ", parent.size)
		print("Vertical Scroll: ", parent.scroll_vertical)
		print("Vertical Scroll Max: ", parent.get_v_scroll_bar().max_value if parent.get_v_scroll_bar() else "N/A")
	print("==========================================\n")

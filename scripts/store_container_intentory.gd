extends VBoxContainer

@export var collected_icons: Array[Sprite2D] = []
@export var icon_spacing: float = 10.0
@export var icons_per_row: int = 4
@export var icon_size: float = 64.0
@export var offset_position: Vector2 = Vector2(20, 320)

func add_icon(icon_sprite: Sprite2D) -> void:
	collected_icons.append(icon_sprite)
	
	icon_sprite.z_index = 9
	
	add_child(icon_sprite)
	
	icon_sprite.position = Vector2.ZERO
	icon_sprite.scale = Vector2(1, 1)
	
	organize_icons()

func organize_icons() -> void:
	for i in range(collected_icons.size()):
		if collected_icons[i] and is_instance_valid(collected_icons[i]):
			var row: int = int(i / float(icons_per_row))
			var col = i % icons_per_row
			
			var x_pos = offset_position.x + (col * (icon_size + icon_spacing))
			var y_pos = offset_position.y + (row * (icon_size + icon_spacing))
			
			collected_icons[i].position = Vector2(x_pos, y_pos)
			collected_icons[i].z_index = 9

func cleanup_invalid_icons() -> void:
	collected_icons = collected_icons.filter(func(icon): return is_instance_valid(icon))

extends ColorRect

func _ready() -> void:
	visible = true
	_update_shader_resolution()
	get_viewport().size_changed.connect(_update_shader_resolution)
	EventBus.subscribe("settings_loaded", _on_settings_loaded, false)
	EventBus.subscribe("change_settings", _on_change_settings, false)

func _update_shader_resolution() -> void:
	var h = get_viewport().get_visible_rect().size.y
	material.set_shader_parameter("resolution", Vector2(480.0, h))

func _on_settings_loaded(_args) -> void:
	visible = GlobalValues.crt_enabled

func _on_change_settings(args) -> void:
	visible = args[0]

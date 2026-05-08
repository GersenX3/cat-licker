extends ColorRect

func _ready() -> void:
	visible = false  # default seguro mientras carga
	EventBus.subscribe("settings_loaded", _on_settings_loaded, false)
	EventBus.subscribe("change_settings", _on_change_settings, false)

func _on_settings_loaded(_args) -> void:
	visible = GlobalValues.crt_enabled

func _on_change_settings(args) -> void:
	visible = args[0]

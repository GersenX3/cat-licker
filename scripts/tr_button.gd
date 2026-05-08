extends Button

@export var translation_key: String = ""

func _ready() -> void:
	_update_text()
	EventBus.subscribe("locale_changed", _on_locale_changed, false)

func _on_locale_changed(_locale) -> void:
	_update_text()

func _update_text() -> void:
	if translation_key == "":
		return
	text = tr(translation_key)

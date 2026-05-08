extends RichTextLabel

@export var translation_key: String = ""
@export var bbcode_before: String = ""
@export var bbcode_after: String = ""

func _ready() -> void:
	# ✅ Leer el locale actual directamente, no depender solo del evento
	_update_text()
	EventBus.subscribe("locale_changed", _on_locale_changed, false)

func _on_locale_changed(_locale) -> void:
	_update_text()

func _update_text() -> void:
	if translation_key == "":
		return
	text = bbcode_before + tr(translation_key) + bbcode_after

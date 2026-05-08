extends VBoxContainer

func _ready() -> void:
	Store.items_creation()
	# ✅ Suscribirse al cambio de idioma (permanente, este nodo vive toda la partida)
	EventBus.subscribe("locale_changed", _on_locale_changed, false)

func _on_locale_changed(_locale) -> void:
	Store.refresh_item_labels()

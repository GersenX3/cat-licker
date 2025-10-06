extends CanvasLayer
class_name EventBusInGameOverview

# Referencias a los nodos de la UI
@onready var panel_container: Panel = $Panel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton
@onready var content_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/ContentContainer
@onready var button: Button = $Button

var label_settings: LabelSettings = preload("res://addons/event_bus_plugin/fonts/LabelSettings.tres")
var timer: Timer

# +++ VARIABLE PARA GUARDAR EL ESTADO ANTERIOR +++
# Usaremos un hash para comparar de forma rápida si los datos han cambiado.
var _last_state_hash: int = 0

func _ready() -> void:
	# Sugerencia: 'pressed' es más intuitivo que 'mouse_entered' para un botón que alterna visibilidad.
	button.mouse_entered.connect(toggleVisibility)
	close_button.pressed.connect(hideOverview)
	
	setVisibility(false)
	
	# Configuración del Timer (más limpia)
	timer = Timer.new()
	timer.wait_time = 1.0 # Podemos revisar más rápido (ej. 1 segundo) porque ahora es barato.
	timer.autostart = true
	add_child(timer)
	
	# +++ CONEXIÓN A LA SEÑAL DEL TIMER +++
	# En lugar de usar 'await' en _process, conectamos a la señal 'timeout'.
	# Esto es más ordenado y eficiente.
	timer.timeout.connect(_on_timer_timeout)

# --- YA NO SE NECESITA _process ---

# +++ NUEVA FUNCIÓN QUE SE EJECUTA CON EL TIMER +++
func _on_timer_timeout() -> void:
	# Solo verificamos cambios si el panel es visible.
	if not panel_container.visible:
		return

	# Obtenemos los datos actuales del EventBus.
	var current_listeners = EventBus.get_all_events()
	var current_history = EventBus.get_emit_history()
	
	# Creamos un 'hash' (un número único) que representa el estado actual de los datos.
	var current_state_hash = hash([current_listeners, current_history])
	
	# Comparamos el hash actual con el último que guardamos.
	# Si son diferentes, significa que algo cambió y debemos actualizar la UI.
	if current_state_hash != _last_state_hash:
		# Actualizamos el hash guardado.
		_last_state_hash = current_state_hash
		# ¡Y solo ahora ejecutamos la actualización visual!
		updateOverview()

func setVisibility(value: bool) -> void:
	panel_container.visible = value
	# Si hacemos visible el panel, forzamos una actualización inmediata
	# por si hubo cambios mientras estaba oculto.
	if value:
		# Reseteamos el hash para forzar la actualización en el próximo tick del timer.
		_last_state_hash = 0
		_on_timer_timeout()

func toggleVisibility() -> void:
	setVisibility(not panel_container.visible)

func hideOverview() -> void:
	setVisibility(false)

# La función updateOverview no necesita cambios, ya que su lógica de dibujar es correcta.
func updateOverview() -> void:
	# Esta función es costosa, por eso ahora la llamamos de forma inteligente.
	for child in content_container.get_children():
		child.queue_free()
	
	# ... el resto de tu código para dibujar los labels sigue igual ...
	var listeners_label: Label = Label.new()
	listeners_label.label_settings = label_settings
	listeners_label.text = "Listeners:"
	content_container.add_child(listeners_label)

	var events = EventBus.get_all_events()
	for event_name in events:
		var event_label = Label.new()
		event_label.label_settings = label_settings
		event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		event_label.text = "- Event: " + event_name
		content_container.add_child(event_label)
		
		var listeners = EventBus.get_listeners_for_event(event_name)
		for listener_info in listeners:
			var object_name = listener_info.get("object_name", "<Unknown>")
			var method_name = listener_info.get("method_name", "<Unknown>")
			var listener_label: Label = Label.new()
			listener_label.label_settings = label_settings
			listener_label.text = "       - Listener: %s.%s" % [object_name, method_name]
			content_container.add_child(listener_label)

	var history_label: Label = Label.new()
	history_label.label_settings = label_settings
	history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	history_label.text = "\nEmit History:"
	content_container.add_child(history_label)

	var emit_history = EventBus.get_emit_history()
	for record in emit_history:
		var timestamp = record["timestamp"]
		var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
		var time_str = "%02d:%02d:%02d" % [datetime.hour, datetime.minute, datetime.second]
		var emit_label: Label = Label.new()
		emit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		emit_label.label_settings = label_settings
		emit_label.text = "[%s] Event: %s Args: %s" % [time_str, record["event_name"], record["args"]]
		content_container.add_child(emit_label)

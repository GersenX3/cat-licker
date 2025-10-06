extends Node

# Reference to the data handler that manages event data persistence
var data_handler: EventBusDataHandler

# Reference to the in-game event overview UI
var event_overview: EventBusInGameOverview

# Dictionary to hold event names and their associated listener info
# MODIFICADO: Ahora almacena diccionarios con el callable y la bandera de autodesuscripción
var _listeners: Dictionary = {}

func _ready() -> void:
	# Initialize the data handler for saving and loading event data
	data_handler = EventBusDataHandler.new()
	
	# Connect to the 'tree_exiting' signal to save data when the game is closing
	tree_exiting.connect(_on_tree_exiting)
	
	# Load and instantiate the in-game event overview UI
	event_overview = preload("res://addons/event_bus_plugin/EventBusInGameOverview.tscn").instantiate()
	add_child(event_overview)
	

func _notification(what) -> void:
	# Handle window close requests to save data before exiting
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await save_event_bus_data()
		get_tree().quit()

func _on_tree_exiting() -> void:
	# Save event data when the scene tree is exiting
	save_event_bus_data()

# MODIFICADO: Se añade el parámetro 'auto_unsubscribe' con valor por defecto 'true'
func subscribe(event_name: String, listener: Callable, auto_unsubscribe: bool = true) -> void:
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	
	# MODIFICADO: Se crea un diccionario para almacenar el callable y su configuración
	var subscription_info = {
		"callable": listener,
		"auto_unsubscribe": auto_unsubscribe
	}
	_listeners[event_name].append(subscription_info)
	print("EventBus: Subscribed listener to event '%s'." % event_name)
	
	# Update the data handler for persistence
	var listener_info = {
		"object_name": listener.get_object().name if is_instance_valid(listener.get_object()) else "<Invalid Object>",
		"method_name": listener.get_method()
	}
	if not data_handler.listeners_data.has(event_name):
		data_handler.listeners_data[event_name] = []
	data_handler.listeners_data[event_name].append(listener_info)

# MODIFICADO: La lógica ahora busca el diccionario que contiene el callable para eliminarlo
func unsubscribe(event_name: String, listener: Callable) -> void:
	if _listeners.has(event_name):
		for i in range(_listeners[event_name].size() - 1, -1, -1):
			var subscription_info = _listeners[event_name][i]
			if subscription_info["callable"] == listener:
				_listeners[event_name].remove_at(i)
				break # Asumimos que no hay duplicados, rompemos el bucle
		
		if _listeners[event_name].is_empty():
			_listeners.erase(event_name)
	
	# Update the data handler to remove the listener information
	if data_handler.listeners_data.has(event_name):
		var listener_info = {
			"object_name": listener.get_object().name if is_instance_valid(listener.get_object()) else "<Invalid Object>",
			"method_name": listener.get_method()
		}
		data_handler.listeners_data[event_name].erase(listener_info)
		if data_handler.listeners_data[event_name].is_empty():
			data_handler.listeners_data.erase(event_name)

# MODIFICADO: Ahora itera, ejecuta y luego desuscribe si la bandera está activa
func emit(event_name: String, args) -> void:
	if _listeners.has(event_name):
		# Copiamos para iterar de forma segura, ya que la lista original puede ser modificada
		var listeners_to_call = _listeners[event_name].duplicate()
		var listeners_to_unsubscribe = []

		print("EventBus: Emitting event '%s' to %d listeners." % [event_name, listeners_to_call.size()])
		
		# Primera pasada: llamar a todos los listeners
		for subscription_info in listeners_to_call:
			if subscription_info["callable"] is Callable:
				subscription_info["callable"].callv([args])
				
				# Si se debe autodesuscribir, lo añadimos a una lista para después
				if subscription_info["auto_unsubscribe"]:
					listeners_to_unsubscribe.append(subscription_info["callable"])
			else:
				push_error("EventBus: Listener is not a Callable.")
		
		# Segunda pasada: desuscribir los que se marcaron
		if not listeners_to_unsubscribe.is_empty():
			for listener in listeners_to_unsubscribe:
				unsubscribe(event_name, listener)
				print("EventBus: Auto-unsubscribed listener from event '%s'." % event_name)

	else:
		print("EventBus: No listeners registered for event '%s'." % event_name)
	
	# Update the data handler with the emitted event information
	var timestamp = int(Time.get_unix_time_from_system())
	var emit_record: Dictionary = {
		"event_name": event_name,
		"args": args,
		"timestamp": timestamp
	}
	data_handler.emit_history_data.append(emit_record)

func save_event_bus_data() -> void:
	data_handler.save_event_data()

func get_all_events() -> Array:
	return data_handler.listeners_data.keys()

func get_listeners_for_event(event_name: String) -> Array:
	if data_handler.listeners_data.has(event_name):
		return data_handler.listeners_data[event_name]
	return []

func get_emit_history() -> Array:
	var original = data_handler.emit_history_data
	var reversed_array = []
	for i in range(original.size() - 1, -1, -1):
		reversed_array.append(original[i])
	return reversed_array

# DialogSystem.gd
# Este script reemplaza a DialogManager y Dialogos.
# Debe ser configurado como un Autoload (Singleton) en Project -> Project Settings -> Autoload.
extends Node

## La escena de la caja de texto que se instanciará.
@onready var text_box_scene = preload("res://scenes/UI/text_box.tscn")
## Ruta al archivo JSON que contiene los diálogos.
@export var dialog_data_path: String = "res://data/dialogos.json"

# --- Señales ---
## Se emite cuando un diálogo comienza. Otros nodos (como el jugador) pueden conectarse a esto.
signal dialogue_started
## Se emite cuando un diálogo termina.
signal dialogue_finished

# --- Estado Interno del Diálogo ---
var stopPlayer: bool = false
var _is_active: bool = false
var _can_advance: bool = false
var _current_lines: Array[String] = []
var _current_line_index: int = 0
var _current_dialog_name: String = ""
var _current_dialog_position: Vector2 # <--- AÑADE ESTA LÍNEA
var _current_character: String = ""
var _current_id: int = -1

# --- Datos y Historial ---
var _dialogue_data: Dictionary = {}
var _dialogue_history: Dictionary = {}

# --- Nodos y Configuración de UI ---
var _text_box_instance: Node
var _auto_advance: bool = false
var _advance_timer: Timer

func _ready() -> void:
	_load_dialogues()
	
	# Configurar el temporizador para el auto-avance
	_advance_timer = Timer.new()
	_advance_timer.one_shot = true
	_advance_timer.timeout.connect(_on_timer_timeout)
	add_child(_advance_timer)

#=============================================================================
# API Pública - Métodos para ser llamados desde otros scripts (NPCs, triggers, etc.)
#=============================================================================

## Inicia un diálogo usando el nombre del personaje y un ID del JSON.
## Inicia un diálogo usando el nombre del personaje y un ID del JSON.
## Inicia un diálogo usando el nombre del personaje y un ID del JSON.
func start_dialog(
	character: String, 
	id: int, 
	position: Vector2, 
	speech_sfx: AudioStream = null, 
	auto_advance: bool = false,
	await_time: float = 2.0,
	use_black_font: bool = false
	) -> void:
		
	if _is_active:
		return
	_current_character = character
	_current_id = id
	# CORRECCIÓN: Se renombra 'lines' a 'dialog_lines' para evitar conflicto.
	var dialog_lines = _get_dialogue_lines(character, id)
	if dialog_lines.is_empty():
		push_warning("No se encontraron líneas de diálogo para %s, ID %s." % [character, id])
		return

	# CORRECCIÓN: Se renombra 'dialog_name' a 'unique_dialog_name'.
	var unique_dialog_name := "%s-%s" % [character, str(id)]
	
	# Se pasan las variables con los nuevos nombres a la función interna.
	_begin_displaying_lines(dialog_lines, position, speech_sfx, auto_advance, await_time, use_black_font, unique_dialog_name)
## Revisa si un diálogo específico ya ha sido mostrado.
func has_played(character: String, id: int) -> bool:
	var dialog_name = "%s-%s" % [character, str(id)]
	return _dialogue_history.has(dialog_name)

## Resetea el historial de diálogos. Útil para empezar una nueva partida.
func reset_history() -> void:
	_dialogue_history.clear()

# En DialogSystem.gd, dentro de la sección "API Pública"

## Fuerza la detención de cualquier diálogo y reinicia el estado completo del sistema.
## Ideal para llamarlo al cambiar de escena.
func reset() -> void:
	# Si un diálogo estaba activo, notificar a otros nodos que terminó.
	if _is_active:
		emit_signal("dialogue_finished")

	# Detener el temporizador para que no se ejecute en la siguiente escena.
	_advance_timer.stop()

	# Eliminar la caja de texto de la pantalla si existe.
	if is_instance_valid(_text_box_instance):
		_text_box_instance.queue_free()

	# Reiniciar todas las variables de estado a sus valores iniciales.
	_is_active = false
	_can_advance = false
	_current_lines.clear()
	_current_line_index = 0
	_current_dialog_name = ""
	_auto_advance = false
	
	# Reiniciar el historial de diálogos vistos.
	# Si prefieres que el historial persista entre escenas, comenta o elimina la línea de abajo.
	_dialogue_history.clear()

#=============================================================================
# Lógica Interna - Métodos que gestionan el sistema
#=============================================================================

# --- Carga de Datos ---
func _load_dialogues() -> void:
	var file := FileAccess.open(dialog_data_path, FileAccess.READ)
	if not FileAccess.file_exists(dialog_data_path):
		push_error("Error al cargar diálogos: El archivo no existe en la ruta '%s'" % dialog_data_path)
		return

	# CORRECCIÓN: Se especifica que el resultado del JSON será un 'Dictionary'.
	var json_data: Dictionary = JSON.parse_string(file.get_as_text())
	
	if json_data:
		# Ahora no hay ambigüedad al usar .get()
		_dialogue_data = json_data.get("dialogos", {})
	else:
		push_error("Error al parsear el archivo JSON de diálogos.")

func _get_dialogue_lines(personaje: String, numero: int) -> Array[String]:
	var num_str := str(numero)
	
	if not _dialogue_data.has(personaje):
		push_error("Personaje no encontrado: ", personaje)
		return []
	
	var dialogos_personaje: Dictionary = _dialogue_data[personaje]
	
	if not dialogos_personaje.has(num_str):
		push_error("Diálogo %d no encontrado para %s" % [numero, personaje])
		return []
	
	var array_raw: Array = dialogos_personaje[num_str]
	var array_strings: Array[String] = []
	
	# Conversión y validación de tipos
	for elemento in array_raw:
		if elemento is String:
			array_strings.append(elemento)
		else:
			push_error("Elemento no es String: ", elemento)
	
	return array_strings
# --- Gestión del Flujo del Diálogo ---

## Lógica central para iniciar la visualización de un conjunto de líneas.
func _begin_displaying_lines(
	lines: Array[String], 
	position: Vector2, 
	sfx: AudioStream, 
	auto: bool, 
	time: float, 
	black_font: bool,
	unique_dialog_name_entry: String
	) -> void:
	
	_is_active = true
	_current_lines = lines
	_current_line_index = 0
	_current_dialog_name = unique_dialog_name_entry
	_auto_advance = auto
	_current_dialog_position = position
	EventBus.emit(_current_character+"_empezo_dialogo", _current_id)
	emit_signal("dialogue_started")
	_show_text_box(position, sfx, time, black_font)

func _advance_line() -> void:
	_current_line_index += 1
	
	if _current_line_index >= _current_lines.size():
		_end_dialogue()
	else:
		# Los parámetros como posición, sfx, etc., se mantienen del inicio.
		_show_text_box(
			_current_dialog_position, # <--- CAMBIA ESTA LÍNEA
			_text_box_instance.speech_sfx, 
			_advance_timer.wait_time, 
			_text_box_instance.black_font
		)

func _end_dialogue() -> void:
	# Limpiar la caja de texto si aún existe
	if is_instance_valid(_text_box_instance):
		_text_box_instance.queue_free()
	var nombre_emision = _current_character+"_termino_dialogo"
	print(nombre_emision)
	EventBus.emit(nombre_emision, _current_id)
	# Marcar en el historial
	if not _current_dialog_name.is_empty():
		_dialogue_history[_current_dialog_name] = true

	# Resetear estado
	_is_active = false
	_can_advance = false
	_current_lines = []
	_current_line_index = 0
	_current_dialog_name = ""

	emit_signal("dialogue_finished")

# --- Gestión de la UI (Caja de Texto) ---

func _show_text_box(position: Vector2, sfx: AudioStream, time: float, black_font: bool) -> void:
	# Liberar la instancia anterior si existe
	if is_instance_valid(_text_box_instance):
		_text_box_instance.queue_free()
		
	_text_box_instance = text_box_scene.instantiate()
	
	# Guardar propiedades para reutilizarlas al avanzar
	_text_box_instance.speech_sfx = sfx 
	_text_box_instance.black_font = black_font 
	
	# Conectar la señal de que terminó de mostrar el texto
	_text_box_instance.finished_displaying.connect(_on_text_box_finished_displaying)

	# --- CORRECCIÓN DEL ERROR DE FUENTE ---
	# Es más seguro acceder a los nodos después de añadirlos al árbol de escena.
	# Añadimos la caja a una capa de UI para asegurar que esté por encima de todo.
	var ui_layer := get_tree().get_root().find_child("UITextBoxLayer", true, false)
	if not ui_layer:
		push_error("No se encontró el nodo CanvasLayer 'UITextBoxLayer'. Asegúrate de que exista en tu escena principal.")
		# Aun así, intentamos añadirlo al root para que no crashee.
		ui_layer = get_tree().get_root()

	ui_layer.add_child(_text_box_instance)
	
	var label: Label = _text_box_instance.get_node_or_null("MarginContainer/Label")
	if label:
		var font_color_key = "theme_override_colors/font_color"
		var shadow_color_key = "theme_override_colors/font_shadow_color"
		if black_font:
			label.set(font_color_key, Color("#1b1f21"))
			label.set(shadow_color_key, Color("#f5ffe8"))
		else:
			label.set(font_color_key, Color("#f5ffe8"))
			label.set(shadow_color_key, Color("#1b1f21"))
	else:
		push_error("El nodo 'Label' no se encontró en la ruta 'MarginContainer/Label' dentro de tu escena de caja de texto.")
		
	_text_box_instance.global_position = position
	_text_box_instance.display_text(_current_lines[_current_line_index], sfx)
	_advance_timer.wait_time = time
	_can_advance = false

# --- Conexiones de Señales y Timers ---

func _on_text_box_finished_displaying() -> void:
	_can_advance = true
	if _auto_advance:
		_advance_timer.start()

func _on_timer_timeout() -> void:
	if _is_active and _can_advance:
		_advance_line()

func _unhandled_input(event: InputEvent) -> void:
	# Avanzar diálogo con la acción del usuario, solo si no es automático.
	if event.is_action_pressed("advance_dialog") and _is_active and _can_advance and not _auto_advance:
		get_viewport().set_input_as_handled() # Prevenir que el input se propague
		_advance_line()

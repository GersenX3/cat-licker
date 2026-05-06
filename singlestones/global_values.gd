extends Node

var hair_balls_total = Big_Number.new(0,0)
var hairs_balls_per_second = Big_Number.new(0,0)
var click_value = Big_Number.new(1,0)

# Sistema de guardado automático
var autosave_timer: Timer
const AUTOSAVE_INTERVAL: float = 10.0  # Segundos entre guardados
const SAVE_FILE_PATH: String = "user://savegame.save"

func _ready() -> void:
	if OS.has_feature("web"):
		   # Espera interacción del usuario
		await get_tree().create_timer(0.1).timeout
	print("=== GLOBAL VALUES INITIALIZED ===")
	print("hair_balls_total: ", hair_balls_total.to_readable_string())
	print("hairs_balls_per_second: ", hairs_balls_per_second.to_readable_string())
	print("click_value: ", click_value.to_readable_string())
	
	# Desactivar clip en todos los RichTextLabel
	disable_clip_on_all_rich_labels()
	
	# 🔍 IMPRIMIR ÁRBOL DE NODOS
	print("\n============================================================")
	print("ÁRBOL DE NODOS COMPLETO")
	print("============================================================")
	print_node_tree(get_tree().root, 0)
	print("============================================================\n")
	
	# 💾 Inicializar sistema de guardado automático
	setup_autosave()
	
	# Cargar partida guardada si existe
	load_game()
	
	#MusicManager.play_song("res://assets/music/Intro.wav", 0, 0)

func _process(_delta: float) -> void:
	# Multiplica mantisa por delta, mantiene exponente
	var increment_mantisa = hairs_balls_per_second.mantisa * _delta# * 128 * 128 * 128
	var increment = Big_Number.new(increment_mantisa, hairs_balls_per_second.exponential)
	
	# Suma al total
	hair_balls_total = hair_balls_total.add_another_big(increment)
	#debug()

func debug():
	if Engine.get_frames_drawn() % 60 == 0:
		print("TOTAL: " + hair_balls_total.to_readable_string() + 
			  " | BpS: " + hairs_balls_per_second.to_readable_string())

# ====================================================================
# 💾 SISTEMA DE GUARDADO AUTOMÁTICO
# ====================================================================

# Configurar el timer de guardado automático
func setup_autosave() -> void:
	autosave_timer = Timer.new()
	autosave_timer.name = "AutosaveTimer"
	autosave_timer.wait_time = AUTOSAVE_INTERVAL
	autosave_timer.one_shot = false
	autosave_timer.autostart = true
	add_child(autosave_timer)
	autosave_timer.timeout.connect(_on_autosave_timer_timeout)
	
	print("💾 Autosave system initialized (every ", AUTOSAVE_INTERVAL, " seconds)")

# Callback cuando el timer se activa
func _on_autosave_timer_timeout() -> void:
	save_game()
	print("💾 Autosave triggered at: ", Time.get_datetime_string_from_system())

# Guardar el juego
func save_game() -> bool:
	print("\n💾 ========== SAVING GAME ==========")
	
	# Obtener el inventario
	var inventory_container = get_node_or_null("/root/Main/UI/Inventory/ScrollContainer/StoreContainerIntentory")
	var inventory_data = []
	if inventory_container and inventory_container.has_method("get_save_data"):
		inventory_data = inventory_container.call("get_save_data")
	
	# ✅ NUEVO: Obtener datos de partículas
	var particle_system = get_node_or_null("/root/Main/UI/Particles")
	var particles_data = []
	if particle_system and particle_system.has_method("get_save_data"):
		particles_data = particle_system.call("get_save_data")
	
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"hair_balls_total": {
			"mantisa": hair_balls_total.mantisa,
			"exponential": hair_balls_total.exponential
		},
		"hairs_balls_per_second": {
			"mantisa": hairs_balls_per_second.mantisa,
			"exponential": hairs_balls_per_second.exponential
		},
		"click_value": {
			"mantisa": click_value.mantisa,
			"exponential": click_value.exponential
		},
		"store_data": Store.save_data() if Store else {},
		"inventory_data": inventory_data,
		"particles_data": particles_data  # ✅ NUEVO: Guardar partículas
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		print("✅ Game saved successfully to: ", SAVE_FILE_PATH)
		print("   Hair balls: ", hair_balls_total.to_readable_string())
		print("   Per second: ", hairs_balls_per_second.to_readable_string())
		print("   Inventory items: ", inventory_data.size())
		print("   Particle systems: ", particles_data.size())
		print("💾 ==================================\n")
		return true
	else:
		push_error("❌ Failed to open save file for writing")
		return false

# Cargar el juego
func load_game() -> bool:
	print("\n💾 ========== LOADING GAME ==========")
	
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("ℹ️  No save file found, starting new game")
		print("💾 ==================================\n")
		return false
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		push_error("❌ Failed to open save file for reading")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("❌ Failed to parse save file JSON")
		return false
	
	var save_data = json.data
	
	# Cargar valores globales
	if save_data.has("hair_balls_total"):
		var hbt = save_data["hair_balls_total"]
		hair_balls_total = Big_Number.new(hbt["mantisa"], hbt["exponential"])
	
	if save_data.has("hairs_balls_per_second"):
		var hbps = save_data["hairs_balls_per_second"]
		hairs_balls_per_second = Big_Number.new(hbps["mantisa"], hbps["exponential"])
	
	if save_data.has("click_value"):
		var cv = save_data["click_value"]
		click_value = Big_Number.new(cv["mantisa"], cv["exponential"])
	
	# Cargar datos de la tienda
	if save_data.has("store_data") and Store:
		Store.load_data(save_data["store_data"])
	
	# Cargar inventario (esperar a que el nodo esté listo)
	if save_data.has("inventory_data"):
		call_deferred("_load_inventory_deferred", save_data["inventory_data"])
	
	# ✅ NUEVO: Cargar partículas
	if save_data.has("particles_data"):
		call_deferred("_load_particles_deferred", save_data["particles_data"])
	
	print("✅ Game loaded successfully")
	print("   Hair balls: ", hair_balls_total.to_readable_string())
	print("   Per second: ", hairs_balls_per_second.to_readable_string())
	
	if save_data.has("timestamp"):
		var save_time = Time.get_datetime_string_from_unix_time(save_data["timestamp"])
		print("   Last saved: ", save_time)
	
	print("💾 ==================================\n")
	return true

func _load_inventory_deferred(inventory_data: Array) -> void:
	var inventory_container = get_node_or_null("/root/Main/UI/Inventory/ScrollContainer/StoreContainerIntentory")
	if inventory_container and inventory_container.has_method("load_save_data"):
		inventory_container.call("load_save_data", inventory_data)
		print("✅ Inventory loaded: ", inventory_data.size(), " items")

func _load_particles_deferred(particles_data: Array) -> void:
	var particle_system = get_node_or_null("/root/Main/UI/Particles")
	if particle_system and particle_system.has_method("load_save_data"):
		particle_system.call("load_save_data", particles_data)
		print("✅ Particle systems loaded: ", particles_data.size(), " systems")

# Guardar manualmente (para llamar desde UI o antes de cerrar)
func manual_save() -> void:
	print("💾 Manual save triggered")
	save_game()

# Borrar partida guardada
func delete_save() -> bool:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("🗑️  Save file deleted")
		
		# Resetear valores
		hair_balls_total = Big_Number.new(0, 0)
		hairs_balls_per_second = Big_Number.new(0, 0)
		click_value = Big_Number.new(1, 0)
		
		return true
	return false

# Verificar si existe una partida guardada
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

# ====================================================================
# 🔍 FUNCIONES DE DEBUG
# ====================================================================

# 🔍 NUEVA FUNCIÓN: Imprimir árbol de nodos completo
func print_node_tree(node: Node, level: int = 0) -> void:
	# Crear indentación según el nivel
	var indent = ""
	for i in range(level):
		indent += "  "
	
	# Información del nodo
	var node_info = indent + "├─ " + node.name
	node_info += " [" + node.get_class() + "]"
	
	# Agregar información extra si es relevante
	if node is Control:
		node_info += " (visible: " + str(node.visible) + ")"
	if node is Button:
		node_info += " (disabled: " + str(node.disabled) + ")"
	if node.has_method("get_child_count"):
		node_info += " (" + str(node.get_child_count()) + " children)"
	
	print(node_info)
	
	# Recursivamente imprimir todos los hijos
	for child in node.get_children():
		print_node_tree(child, level + 1)

# 🔍 NUEVA FUNCIÓN: Buscar nodos por nombre o tipo
func find_nodes_by_name(search_name: String) -> Array:
	var found_nodes = []
	_recursive_find_by_name(get_tree().root, search_name, found_nodes)
	return found_nodes

func _recursive_find_by_name(node: Node, search_name: String, result: Array) -> void:
	if search_name.to_lower() in node.name.to_lower():
		result.append(node)
	
	for child in node.get_children():
		_recursive_find_by_name(child, search_name, result)

# 🔍 NUEVA FUNCIÓN: Imprimir solo botones de la tienda
func print_store_buttons() -> void:
	print("\n============================================================")
	print("BOTONES DE LA TIENDA")
	print("============================================================")
	
	var store_container = get_node_or_null("/root/Main/UI/Store/ScrollContainer/StoreContainer")
	if store_container:
		print("✅ StoreContainer encontrado: ", store_container.name)
		print("   Total de hijos: ", store_container.get_child_count())
		
		for i in range(store_container.get_child_count()):
			var child = store_container.get_child(i)
			var info = "  [" + str(i) + "] " + child.name + " [" + child.get_class() + "]"
			
			if child is Button:
				info += " (visible: " + str(child.visible) + ", disabled: " + str(child.disabled) + ")"
				
				# Si tiene el script personalizado, mostrar más info
				if child.has_method("calculate_current_cost"):
					info += " | Cost: " + str(child.call("calculate_current_cost").to_readable_string())
					info += " | State: " + str(child.get("current_state"))
			
			print(info)
	else:
		print("❌ StoreContainer NO encontrado")
	
	print("============================================================\n")

# 🔍 NUEVA FUNCIÓN: Buscar un path específico
func check_node_path(path: String) -> void:
	var node = get_node_or_null(path)
	if node:
		print("✅ Path encontrado: ", path)
		print("   Nombre: ", node.name)
		print("   Tipo: ", node.get_class())
		print("   Hijos: ", node.get_child_count())
	else:
		print("❌ Path NO encontrado: ", path)

# Buscar todos los RichTextLabel y desactivar clip_contents
func disable_clip_on_all_rich_labels() -> void:
	var root = get_tree().root
	_recursive_disable_clip(root)
	print("Clip desactivado en todos los RichTextLabel")

# Función recursiva para recorrer todos los nodos
func _recursive_disable_clip(node: Node) -> void:
	# Si el nodo es un RichTextLabel, desactivar clip
	if node is RichTextLabel:
		node.clip_contents = false
		print("Clip desactivado en: ", node.name)
	
	# Recorrer todos los hijos
	for child in node.get_children():
		_recursive_disable_clip(child)

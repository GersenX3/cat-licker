extends Node

var hair_balls_total = Big_Number.new(0, 0)
var hairs_balls_per_second = Big_Number.new(0, 0)
var click_value = Big_Number.new(1, 0)

var autosave_timer: Timer
const AUTOSAVE_INTERVAL: float = 10.0
const SAVE_FILE_PATH: String = "user://savegame.save"
const BACKUP_FILE_PATH: String = "user://savegame.bak"

# Para offline progress
var _last_save_timestamp: int = 0
const MAX_OFFLINE_SECONDS: float = 86400.0  # Máximo 24h de progreso offline

func _ready() -> void:
	if OS.has_feature("web"):
		await get_tree().create_timer(0.1).timeout

	disable_clip_on_all_rich_labels()
	setup_autosave()
	load_game()

func _process(_delta: float) -> void:
	var increment = Big_Number.new(
		hairs_balls_per_second.mantisa * _delta,
		hairs_balls_per_second.exponential
	)
	hair_balls_total = hair_balls_total.add_another_big(increment)

# ====================================================================
# 💾 GUARDADO
# ====================================================================

func setup_autosave() -> void:
	autosave_timer = Timer.new()
	autosave_timer.wait_time = AUTOSAVE_INTERVAL
	autosave_timer.one_shot = false
	autosave_timer.autostart = true
	add_child(autosave_timer)
	autosave_timer.timeout.connect(_on_autosave_timer_timeout)

func _on_autosave_timer_timeout() -> void:
	save_game()

func save_game() -> bool:
	# 📦 Recolectar estado de botones de la tienda
	var buttons_data = _collect_store_buttons_data()

	# 📦 Inventario
	var inventory_data = []
	var inventory_container = get_node_or_null("/root/Main/UI/Inventory/ScrollContainer/StoreContainerIntentory")
	if inventory_container and inventory_container.has_method("get_save_data"):
		inventory_data = inventory_container.call("get_save_data")

	# 📦 Partículas
	var particles_data = []
	var particle_system = get_node_or_null("/root/Main/UI/Particles")
	if particle_system and particle_system.has_method("get_save_data"):
		particles_data = particle_system.call("get_save_data")

	var save_data = {
		"version": "1.1",
		"timestamp": Time.get_unix_time_from_system(),
		"hair_balls_total": {
			"mantisa": hair_balls_total.mantisa,
			"exponential": hair_balls_total.exponential
		},
		"click_value": {
			"mantisa": click_value.mantisa,
			"exponential": click_value.exponential
		},
		"store_data": Store.save_data() if Store else {},
		"buttons_data": buttons_data,
		"inventory_data": inventory_data,
		"particles_data": particles_data
	}

	# 🔒 Backup: copiar save anterior antes de sobreescribir
	_backup_save()

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("✅ Juego guardado | Balls: ", hair_balls_total.to_readable_string(), " | BpS: ", hairs_balls_per_second.to_readable_string())
		return true
	else:
		push_error("❌ No se pudo abrir el archivo de guardado")
		return false

func _backup_save() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var original = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if original:
			var content = original.get_as_text()
			original.close()
			var backup = FileAccess.open(BACKUP_FILE_PATH, FileAccess.WRITE)
			if backup:
				backup.store_string(content)
				backup.close()

func _collect_store_buttons_data() -> Array:
	var result = []
	var store_container = get_node_or_null("/root/Main/UI/Store/ScrollContainer/StoreContainer")
	if not store_container:
		return result
	for child in store_container.get_children():
		if child.has_method("get_save_data"):
			result.append(child.call("get_save_data"))
	return result

# ====================================================================
# 📂 CARGA
# ====================================================================

func load_game() -> bool:
	# Intentar cargar save principal, si falla usar backup
	var loaded = _try_load_from(SAVE_FILE_PATH)
	if not loaded and FileAccess.file_exists(BACKUP_FILE_PATH):
		push_warning("⚠️ Save principal fallido, cargando backup...")
		loaded = _try_load_from(BACKUP_FILE_PATH)
	return loaded

func _try_load_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		print("ℹ️ No se encontró archivo en: ", path)
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("❌ No se pudo leer: ", path)
		return false

	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("❌ JSON inválido en: ", path)
		file.close()
		return false
	file.close()

	var data = json.data

	# ✅ Validar estructura mínima
	if not _validate_save_data(data):
		push_error("❌ Datos de guardado corruptos o incompletos")
		return false

	# 💰 Cargar valores básicos
	hair_balls_total = _parse_big_number(data, "hair_balls_total", Big_Number.new(0, 0))
	click_value      = _parse_big_number(data, "click_value",      Big_Number.new(1, 0))

	# 📅 Guardar timestamp para calcular offline progress después
	_last_save_timestamp = int(data.get("timestamp", 0))

	# 🏪 Cargar tienda
	if data.has("store_data") and Store:
		Store.load_data(data["store_data"])

	# 🔘 Cargar estado de botones (deferred para esperar que la escena esté lista)
	var buttons_data  = data.get("buttons_data",  [])
	var inventory_data = data.get("inventory_data", [])
	var particles_data = data.get("particles_data", [])

	call_deferred("_deferred_load_sequence", buttons_data, inventory_data, particles_data)

	print("✅ Datos base cargados | Balls: ", hair_balls_total.to_readable_string())
	return true

# Carga diferida en secuencia para garantizar el orden correcto
func _deferred_load_sequence(buttons_data: Array, inventory_data: Array, particles_data: Array) -> void:
	# 1. Restaurar estado de botones
	_apply_store_buttons_data(buttons_data)

	# 2. Recalcular BPS desde los botones cargados (fuente de verdad)
	recalculate_bps()

	# 3. Aplicar progreso offline
	_apply_offline_progress()

	# 4. Cargar inventario y partículas
	var inventory_container = get_node_or_null("/root/Main/UI/Inventory/ScrollContainer/StoreContainerIntentory")
	if inventory_container and inventory_container.has_method("load_save_data"):
		inventory_container.call("load_save_data", inventory_data)

	var particle_system = get_node_or_null("/root/Main/UI/Particles")
	if particle_system and particle_system.has_method("load_save_data"):
		particle_system.call("load_save_data", particles_data)

	print("✅ Carga completa | BpS recalculado: ", hairs_balls_per_second.to_readable_string())

func _apply_store_buttons_data(buttons_data: Array) -> void:
	var store_container = get_node_or_null("/root/Main/UI/Store/ScrollContainer/StoreContainer")
	if not store_container:
		push_warning("⚠️ StoreContainer no encontrado al cargar botones")
		return

	for button_data in buttons_data:
		var idx = button_data.get("store_index", -1)
		for child in store_container.get_children():
			if child.has_method("apply_save_data") and child.get("store_index") == idx:
				child.call("apply_save_data", button_data)
				break

# Suma base_production * quantity de cada botón de tienda
func recalculate_bps() -> void:
	hairs_balls_per_second = Big_Number.new(0, 0)
	var store_container = get_node_or_null("/root/Main/UI/Store/ScrollContainer/StoreContainer")
	if not store_container:
		return
	for child in store_container.get_children():
		if child.has_method("get_production_contribution"):
			var contrib = child.call("get_production_contribution")
			hairs_balls_per_second = hairs_balls_per_second.add_another_big(contrib)
	print("🔄 BpS recalculado: ", hairs_balls_per_second.to_readable_string())

func _apply_offline_progress() -> void:
	if _last_save_timestamp <= 0:
		return
	var now = int(Time.get_unix_time_from_system())
	var elapsed = clamp(float(now - _last_save_timestamp), 0.0, MAX_OFFLINE_SECONDS)
	if elapsed < 5.0:
		return  # Menos de 5s, no vale la pena

	# BPS * segundos transcurridos
	var offline_gain = hairs_balls_per_second.multiply(Big_Number.from_float(elapsed))
	hair_balls_total = hair_balls_total.add_another_big(offline_gain)
	print("⏰ Progreso offline: +", offline_gain.to_readable_string(), " (", int(elapsed), "s fuera)")

# ====================================================================
# 🔍 VALIDACIÓN
# ====================================================================

func _validate_save_data(data: Dictionary) -> bool:
	if not data is Dictionary:
		return false
	# Campos mínimos requeridos
	for required in ["hair_balls_total", "click_value", "timestamp"]:
		if not data.has(required):
			push_warning("⚠️ Campo faltante en save: ", required)
			return false
	return true

func _parse_big_number(data: Dictionary, key: String, fallback: Big_Number) -> Big_Number:
	if not data.has(key):
		return fallback
	var d = data[key]
	if not (d.has("mantisa") and d.has("exponential")):
		return fallback
	# Validar que son números
	if not (d["mantisa"] is float or d["mantisa"] is int):
		return fallback
	return Big_Number.new(float(d["mantisa"]), int(d["exponential"]))

# ====================================================================
# 🗑️ UTILIDADES
# ====================================================================

func manual_save() -> void:
	save_game()

func delete_save() -> bool:
	var deleted = false
	for path in [SAVE_FILE_PATH, BACKUP_FILE_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
			deleted = true
	if deleted:
		hair_balls_total        = Big_Number.new(0, 0)
		hairs_balls_per_second  = Big_Number.new(0, 0)
		click_value             = Big_Number.new(1, 0)
	return deleted

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func disable_clip_on_all_rich_labels() -> void:
	_recursive_disable_clip(get_tree().root)

func _recursive_disable_clip(node: Node) -> void:
	if node is RichTextLabel:
		node.clip_contents = false
	for child in node.get_children():
		_recursive_disable_clip(child)

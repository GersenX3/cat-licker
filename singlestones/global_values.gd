extends Node

var hair_balls_total = Big_Number.new(0, 0)
var hairs_balls_per_second = Big_Number.new(0, 0)
var click_value = Big_Number.new(1, 0)

var autosave_timer: Timer
const AUTOSAVE_INTERVAL: float = 10.0
const SAVE_FILE_PATH: String = "user://savegame.save"
const BACKUP_FILE_PATH: String = "user://savegame.bak"
const SETTINGS_FILE_PATH: String = "user://settings.cfg"

# Para offline progress
var _last_save_timestamp: int = 0
const MAX_OFFLINE_SECONDS: float = 86400.0

# ====================================================================
# 🌐 IDIOMAS
# ====================================================================

const LANGUAGES = [
	["es", "Español"],
	["en", "English"]
]

var current_locale: String = "en"

func _load_translations() -> void:
	var es = Translation.new()
	es.locale = "es"
	var en = Translation.new()
	en.locale = "en"

	var entries = {
		"RESET": ["Reiniciar", "Reset"],
		"SAVE": ["Guardar", "Save"],
		"MUSIC": ["Musica", "Music"],
		"SFX": ["Efectos", "SFX"],
		"BALLS": ["bolas de pelo", "hair balls"],
		"PER_SECOND": ["por segundo", "per second"],
		"STORE": ["Tienda","Store"],
		"STOCK": ["Cosas","Stock"],
		"ITEM_0_NAME": ["Lengua Áspera", "Rough Tongue"],
		"ITEM_0_DESC": ["Una lengua que raspa sin descanso", "A tongue that scratches nonstop"],
		"ITEM_1_NAME": ["Cepillo Mágico", "Magic Brush"],
		"ITEM_1_DESC": ["Cepilla solo y genera ronroneos", "Brushes on its own generating purrs"],
		"ITEM_2_NAME": ["Bolita de Estambre", "Little Yarn Ball"],
		"ITEM_2_DESC": ["Rueda eternamente por el suelo", "Rolls forever across the floor"],
		"ITEM_3_NAME": ["Rascador Hipnótico", "Hypnotic Scratching Post"],
		"ITEM_3_DESC": ["Hipnotiza a cualquier gato", "Hypnotizes any cat"],
		"ITEM_4_NAME": ["Hierba Gatera Cuántica", "Quantum Catnip"],
		"ITEM_4_DESC": ["Existe en múltiples estados de éxtasis", "Exists in multiple states of ecstasy"],
		"ITEM_5_NAME": ["Láser Perpetuo", "Perpetual Laser"],
		"ITEM_5_DESC": ["Nunca se apaga nunca se atrapa", "Never turns off never gets caught"],
		"ITEM_6_NAME": ["Caja de Cartón Dimensional", "Dimensional Cardboard Box"],
		"ITEM_6_DESC": ["Cabe un universo adentro", "Fits a universe inside"],
		"ITEM_7_NAME": ["Pluma Cósmica", "Cosmic Feather"],
		"ITEM_7_DESC": ["Flota con la gravedad del cosmos", "Floats with cosmic gravity"],
		"ITEM_8_NAME": ["Ratón Mecánico", "Mechanical Mouse"],
		"ITEM_8_DESC": ["Corre solo y nunca se cansa", "Runs on its own and never tires"],
		"ITEM_9_NAME": ["Torre Rascadora Infinita", "Infinite Scratching Tower"],
		"ITEM_9_DESC": ["Llega hasta las estrellas", "Reaches up to the stars"],
		"ITEM_10_NAME": ["Fuente Eterna de Leche", "Eternal Milk Fountain"],
		"ITEM_10_DESC": ["Leche fresca para siempre", "Fresh milk forever"],
		"ITEM_11_NAME": ["Túnel Teletransportador", "Teleport Tunnel"],
		"ITEM_11_DESC": ["Apareces donde menos lo esperas", "You appear where least expected"],
		"ITEM_12_NAME": ["Hamaca Solar", "Solar Hammock"],
		"ITEM_12_DESC": ["Calentita y balanceándose sola", "Warm and swinging on its own"],
		"ITEM_13_NAME": ["Robot Acariciador", "Petting Robot"],
		"ITEM_13_DESC": ["Mimos garantizados 24/7", "Guaranteed petting 24/7"],
		"ITEM_14_NAME": ["Ventana a Otra Dimensión", "Window to Another Dimension"],
		"ITEM_14_DESC": ["Los pájaros ahí son infinitos", "The birds there are infinite"],
		"ITEM_15_NAME": ["Collar Generador", "Generator Collar"],
		"ITEM_15_DESC": ["Convierte ronroneos en energía", "Converts purring into energy"],
		"ITEM_16_NAME": ["Arena Mágica Autolimpiante", "Self-Cleaning Magic Litter"],
		"ITEM_16_DESC": ["Siempre impecable siempre fresca", "Always spotless always fresh"],
		"ITEM_17_NAME": ["Clonador Felino", "Feline Cloner"],
		"ITEM_17_DESC": ["El doble de gatos el doble de caos", "Double the cats double the chaos"],
		"ITEM_18_NAME": ["Máquina del Tiempo Gatuna", "Kitty Time Machine"],
		"ITEM_18_DESC": ["Para robar snacks del pasado", "To steal snacks from the past"],
		"ITEM_19_NAME": ["MANGO", "MANGO"],
		"ITEM_19_DESC": ["Él sabe lo que hizo", "He knows what he did"],
	}

	for key in entries:
		es.add_message(key, entries[key][0])
		en.add_message(key, entries[key][1])

	TranslationServer.add_translation(es)
	TranslationServer.add_translation(en)
	print("✅ Traducciones cargadas")

func _load_saved_locale() -> void:
	var saved = "es"
	if FileAccess.file_exists(SETTINGS_FILE_PATH):
		var config = ConfigFile.new()
		config.load(SETTINGS_FILE_PATH)
		saved = config.get_value("locale", "language", "es")
	# ✅ Esperar a que toda la escena esté lista
	call_deferred("apply_locale", saved)

func apply_locale(locale: String) -> void:
	current_locale = locale
	TranslationServer.set_locale(locale)
	_save_locale(locale)
	EventBus.emit("locale_changed", locale)
	print("🌐 Idioma aplicado: ", locale)

func _save_locale(locale: String) -> void:
	var config = ConfigFile.new()
	if FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.load(SETTINGS_FILE_PATH)
	config.set_value("locale", "language", locale)
	config.save(SETTINGS_FILE_PATH)

func _on_change_to_english(_args) -> void:
	apply_locale("en")

func _on_change_to_spanish(_args) -> void:
	apply_locale("es")

# ====================================================================
# 🚀 INICIO
# ====================================================================

func _ready() -> void:
	if OS.has_feature("web"):
		await get_tree().create_timer(0.1).timeout

	_load_translations()

	EventBus.subscribe("change_to_english", _on_change_to_english, false)
	EventBus.subscribe("cambio_a_español",  _on_change_to_spanish,  false)

	call_deferred("load_settings")  # ✅ carga locale + settings juntos

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
	var buttons_data = _collect_store_buttons_data()

	var inventory_data = []
	var inventory_container = get_node_or_null("/root/Main/UI/Inventory/ScrollContainer/StoreContainerIntentory")
	if inventory_container and inventory_container.has_method("get_save_data"):
		inventory_data = inventory_container.call("get_save_data")

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

	if not _validate_save_data(data):
		push_error("❌ Datos de guardado corruptos o incompletos")
		return false

	hair_balls_total = _parse_big_number(data, "hair_balls_total", Big_Number.new(0, 0))
	click_value      = _parse_big_number(data, "click_value",      Big_Number.new(1, 0))

	_last_save_timestamp = int(data.get("timestamp", 0))

	if data.has("store_data") and Store:
		Store.load_data(data["store_data"])

	var buttons_data   = data.get("buttons_data",   [])
	var inventory_data = data.get("inventory_data", [])
	var particles_data = data.get("particles_data", [])

	call_deferred("_deferred_load_sequence", buttons_data, inventory_data, particles_data)

	print("✅ Datos base cargados | Balls: ", hair_balls_total.to_readable_string())
	return true

func _deferred_load_sequence(buttons_data: Array, inventory_data: Array, particles_data: Array) -> void:
	_apply_store_buttons_data(buttons_data)
	recalculate_bps()
	_apply_offline_progress()

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
		return

	var offline_gain = hairs_balls_per_second.multiply(Big_Number.from_float(elapsed))
	hair_balls_total = hair_balls_total.add_another_big(offline_gain)
	print("⏰ Progreso offline: +", offline_gain.to_readable_string(), " (", int(elapsed), "s fuera)")

# ====================================================================
# 🔍 VALIDACIÓN
# ====================================================================

func _validate_save_data(data: Dictionary) -> bool:
	if not data is Dictionary:
		return false
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

# ====================================================================
# ⚙️ SETTINGS
# ====================================================================

var crt_enabled: bool = true
var music_volume: float = 100.0
var sfx_volume: float = 100.0

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		call_deferred("_emit_settings_loaded")  # ✅ también en defaults
		return
	var config = ConfigFile.new()
	config.load(SETTINGS_FILE_PATH)
	crt_enabled  = config.get_value("settings", "crt",   true)
	music_volume = config.get_value("settings", "music", 100.0)
	sfx_volume   = config.get_value("settings", "sfx",   100.0)
	var locale = config.get_value("locale", "language", "es")
	apply_locale(locale)
	print("⚙️ Settings cargados | CRT: ", crt_enabled, " | Music: ", music_volume, " | SFX: ", sfx_volume)
	EventBus.emit("settings_loaded", null)

func _emit_settings_loaded() -> void:
	EventBus.emit("settings_loaded", null)

func save_settings(crt: bool, music: float, sfx: float) -> void:
	crt_enabled  = crt
	music_volume = music
	sfx_volume   = sfx
	var config = ConfigFile.new()
	# Preservar locale si ya existe
	if FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.load(SETTINGS_FILE_PATH)
	config.set_value("settings", "crt",   crt)
	config.set_value("settings", "music", music)
	config.set_value("settings", "sfx",   sfx)
	config.save(SETTINGS_FILE_PATH)
	print("⚙️ Settings guardados | CRT: ", crt, " | Music: ", music, " | SFX: ", sfx)
	var args = [crt, music, sfx]
	print(args)
	EventBus.emit("change_settings", args)

extends Node

# Señales para actualizar UI
signal item_purchased(item: StoreItem)
signal balance_changed(new_balance: float)
signal production_changed(new_bps: float)

# Rutas de los items
const ITEM_PATHS = [
	"res://resources/items/0_Rough Tongue.tres",
	"res://resources/items/1_Magic Brush.tres",
	"res://resources/items/2_Little Yarn Ball.tres",
	"res://resources/items/3_Hypnotic Scratching Post.tres",
	"res://resources/items/4_Quantum Catnip.tres",
	"res://resources/items/5_Perpetual Laser.tres",
	"res://resources/items/6_Dimensional Cardboard Box.tres",
	"res://resources/items/7_Cosmic Feather.tres",
	"res://resources/items/8_Mechanical Mouse.tres",
	"res://resources/items/9_Infinite Scratching Tower.tres",
	"res://resources/items/10_Eternal Milk Fountain.tres",
	"res://resources/items/11_Teleport Tunnel.tres",
	"res://resources/items/12_Solar Hammock.tres",
	"res://resources/items/13_Petting Robot.tres",
	"res://resources/items/14_Window to Another Dimension.tres",
	"res://resources/items/15_Generator Collar.tres",
	"res://resources/items/16_Self-Cleaning Magic Litter.tres",
	"res://resources/items/17_Feline Cloner.tres",
	"res://resources/items/18_Kitty Time Machine.tres",
	"res://resources/items/19_MANGO.tres"
]

# Catálogo de items (configura en el Inspector o por código)
var store_items: Array[StoreItem] = []
var reference_item_button = preload("res://scenes/item.tscn")
var v_box_container: VBoxContainer

func _ready() -> void:
	initialize()

#func _process(_delta: float) -> void:
	#if can_afford(0):
		#purchase_item(0)
# Referencia al singleton de GameManager

# Crear items por defecto basados en Cookie Clicker
#func _create_default_items() -> void:
	## Lengua Áspera (equivalente a Cursor)
	#var tongue = StoreItem.new()
	#tongue.item_name = "Lengua Áspera"
	#tongue.description = "Una lengua rasposa que lame constantemente"
	#tongue.base_cost = Big_Number.new(1,1)
	#tongue.base_production = Big_Number.new(1,1)
	#tongue.cost_multiplier = Big_Number.new(1,1)
	#store_items.append(tongue)

# Intentar comprar un item
func purchase_item(item_index: int) -> bool:
	GlobalValues.dlog("=== PURCHASE ATTEMPT ===")
	GlobalValues.dlog("Item index: ", item_index)

	if item_index < 0 or item_index >= store_items.size():
		push_error("Store.purchase_item: index out of bounds (%d)" % item_index)
		return false

	var item = store_items[item_index]
	GlobalValues.dlog("Item name: ", item.item_name)
	GlobalValues.dlog("Item quantity before: ", item.quantity)

	var cost = item.get_current_cost()
	GlobalValues.dlog("Cost calculated: ", cost.to_readable_string())
	GlobalValues.dlog("Current balance: ", GlobalValues.hair_balls_total.to_readable_string())

	var has_enough = GlobalValues.hair_balls_total.is_greater_or_equal(cost)
	GlobalValues.dlog("Has enough funds? ", has_enough)

	if has_enough:
		GlobalValues.dlog("PURCHASE APPROVED - Processing...")

		var balance_before = GlobalValues.hair_balls_total
		GlobalValues.hair_balls_total = GlobalValues.hair_balls_total.subtract(cost)

		GlobalValues.dlog("Balance before: ", balance_before.to_readable_string())
		GlobalValues.dlog("Balance after: ", GlobalValues.hair_balls_total.to_readable_string())

		item.quantity += 1
		GlobalValues.dlog("Item quantity after: ", item.quantity)

		_update_total_production()

		# Emitir señales (la UI escucha balance/production en GlobalValues)
		emit_signal("item_purchased", item)
		GlobalValues.notify_balance_changed()
		GlobalValues.dlog("=== PURCHASE COMPLETED ===\n")

		return true
	else:
		GlobalValues.dlog("PURCHASE DENIED - Insufficient funds")
		GlobalValues.dlog("=== PURCHASE FAILED ===\n")

	return false

# Comprar múltiples unidades de un item
func purchase_bulk(item_index: int, amount: int) -> int:
	if item_index < 0 or item_index >= store_items.size():
		return 0
	
	var item = store_items[item_index]
	var cost = item.get_bulk_cost(amount)

	var purchased = 0

	if GlobalValues.hair_balls_total.is_greater_or_equal(cost):
		# Comprar la cantidad completa
		GlobalValues.hair_balls_total = GlobalValues.hair_balls_total.subtract(cost)
		item.quantity += amount
		purchased = amount
	else:
		# Comprar lo que se pueda
		purchased = item.try_bulk_purchase(GlobalValues.hair_balls_total, amount)
		if purchased > 0:
			cost = item.get_bulk_cost(purchased)
			GlobalValues.hair_balls_total = GlobalValues.hair_balls_total.subtract(cost)

	if purchased > 0:
		_update_total_production()
		emit_signal("item_purchased", item)
		GlobalValues.notify_balance_changed()

	return purchased

# Actualizar la producción total en el GameManager
func _update_total_production() -> void:
	var total_bps = Big_Number.new(0, 0)

	for item in store_items:
		total_bps = total_bps.add_another_big(item.get_total_production())

	GlobalValues.hairs_balls_per_second = total_bps
	emit_signal("production_changed", total_bps)
	GlobalValues.notify_production_changed()

# Obtener item por índice
func get_item(index: int) -> StoreItem:
	if index >= 0 and index < store_items.size():
		return store_items[index]
	return null

# Verificar si un item puede ser comprado
func can_afford(item_index: int) -> bool:
	if item_index < 0 or item_index >= store_items.size():
		return false
	
	var item = store_items[item_index]
	return GlobalValues.hair_balls_total.is_greater_or_equal(item.get_current_cost())

# Guardar progreso de la tienda (formato: dict por item_name → quantity).
# Indexar por nombre y no por posición evita corromper saves al reordenar
# o insertar items nuevos en medio del catálogo.
func save_data() -> Dictionary:
	var items_by_name := {}
	for item in store_items:
		items_by_name[item.item_name] = item.to_dict()

	return {
		"version": 2,
		"items": items_by_name
	}

# Cargar progreso de la tienda
func load_data(data: Dictionary) -> void:
	if data.has("items"):
		var items_raw = data["items"]

		if items_raw is Dictionary:
			# Formato nuevo (v2): { "Lengua Áspera": { "quantity": 5 }, ... }
			for item in store_items:
				if items_raw.has(item.item_name):
					item.from_dict(items_raw[item.item_name])
		elif items_raw is Array:
			# Compatibilidad con saves viejos (v1): array posicional.
			# Si el item guardado trae item_name lo casamos por nombre; si no,
			# caemos al pareo por índice como antes.
			var matched_by_name := false
			for entry in items_raw:
				if entry is Dictionary and entry.has("item_name"):
					matched_by_name = true
					for item in store_items:
						if item.item_name == entry["item_name"]:
							item.from_dict(entry)
							break
			if not matched_by_name:
				for i in range(min(items_raw.size(), store_items.size())):
					store_items[i].from_dict(items_raw[i])

	_update_total_production()

	# ✅ ACTUALIZAR BOTONES CON LAS NUEVAS CANTIDADES
	update_button_quantities()

# ✅ NUEVA FUNCIÓN: Actualizar cantidades en los botones
func update_button_quantities() -> void:
	if not v_box_container:
		return
	
	for i in range(v_box_container.get_child_count()):
		var button = v_box_container.get_child(i)
		if button and button.has_method("update_labels") and i < store_items.size():
			button.quantity = store_items[i].quantity
			button.call("update_labels")
			GlobalValues.dlog("🔄 Updated button ", button.item_name, " quantity: ", button.quantity)

# Crear botones de items
func items_creation() -> void:
	if not v_box_container:
		return
	
	# Limpiar botones existentes antes de crear nuevos
	for child in v_box_container.get_children():
		child.free()
	
	store_items.sort_custom(func(a, b): return a.store_index < b.store_index)
	
	var index = 0
	for item in store_items:
		var new_item = reference_item_button.instantiate()
		
		new_item.store_index = int(index)
		new_item.item_name = tr("ITEM_%d_NAME" % index)
		new_item.description = tr("ITEM_%d_DESC" % index)
		new_item.item_icon = item.icon
		new_item.base_cost = item.base_cost
		new_item.base_production = item.base_production
		new_item.cost_multiplier = item.cost_multiplier
		new_item.amort_time = item.amort_time
		new_item.quantity = item.quantity
		
		new_item.name = item.item_name
		v_box_container.add_child(new_item)
		
		index += 1

func _load_store_items() -> void:
	if !store_items.is_empty():
		return
	GlobalValues.dlog("🔄 Loading items...")

	for item_path in ITEM_PATHS:
		var item = load(item_path) as StoreItem
		if item:
			var item_instance = item.duplicate()
			item_instance.quantity = 0
			store_items.append(item_instance)
			GlobalValues.dlog("✅ Loaded: ", item.item_name)
		else:
			push_error("❌ Failed to load: " + item_path)

	GlobalValues.dlog("📦 Total items loaded: ", store_items.size())

# En store_manager.gd — nueva función
func refresh_item_labels() -> void:
	if not v_box_container:
		return
	
	for i in range(v_box_container.get_child_count()):
		var button = v_box_container.get_child(i)
		if button and i < store_items.size():
			button.item_name = tr("ITEM_%d_NAME" % i)
			button.description = tr("ITEM_%d_DESC" % i)
			if button.has_method("update_labels"):
				button.call("update_labels")

func reset() -> void:
	for item in store_items:
		item.quantity = 0
	store_items.clear()
	if v_box_container:
		for child in v_box_container.get_children():
			child.free()  # ← inmediato, no diferido
	v_box_container = null
	_update_total_production()

func initialize() -> void:
	v_box_container = get_node_or_null("/root/Main/UI/Store/ScrollContainer/StoreContainer")
	_load_store_items()
	_update_total_production()
	items_creation()

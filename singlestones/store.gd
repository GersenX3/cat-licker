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
@onready var v_box_container: VBoxContainer = get_node_or_null("/root/Main/UI/Store/ScrollContainer/StoreContainer")

func _ready() -> void:
	print("=== STORE INITIALIZATION START ===")
	print("GlobalValues.hair_balls_total BEFORE: ", GlobalValues.hair_balls_total.to_readable_string())
	print("GlobalValues.hairs_balls_per_second BEFORE: ", GlobalValues.hairs_balls_per_second.to_readable_string())
	
	_load_store_items()
	
	print("\n=== ITEMS LOADED ===")
	for i in range(store_items.size()):
		var item = store_items[i]
		print("Item[", i, "]: ", item.item_name, " | quantity: ", item.quantity, " | base_prod: ", item.base_production.to_readable_string())
	
	_update_total_production()
	
	print("\n=== AFTER UPDATE PRODUCTION ===")
	print("GlobalValues.hairs_balls_per_second AFTER: ", GlobalValues.hairs_balls_per_second.to_readable_string())


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
	print("=== PURCHASE ATTEMPT ===")
	print("Item index: ", item_index)
	
	if item_index < 0 or item_index >= store_items.size():
		print("ERROR: Index out of bounds")
		return false
	
	var item = store_items[item_index]
	print("Item name: ", item.item_name)
	print("Item quantity before: ", item.quantity)
	
	var cost = item.get_current_cost()
	print("Cost calculated: ", cost.to_readable_string())
	print("Current balance: ", GlobalValues.hair_balls_total.to_readable_string())
	
	# Verificar si hay suficiente balance
	var has_enough = GlobalValues.hair_balls_total.is_greater_or_equal(cost)
	print("Has enough funds? ", has_enough)
	print("Comparison result (balance >= cost): ", has_enough)
	
	if has_enough:
		print("✓ PURCHASE APPROVED - Processing...")
		
		# Realizar la compra
		var balance_before = GlobalValues.hair_balls_total
		GlobalValues.hair_balls_total = GlobalValues.hair_balls_total.subtract(cost)
		
		print("Balance before: ", balance_before.to_readable_string())
		print("Balance after: ", GlobalValues.hair_balls_total.to_readable_string())
		
		item.quantity += 1
		print("Item quantity after: ", item.quantity)
		
		# Actualizar producción total
		_update_total_production()
		
		# Emitir señales
		print("item_purchased", item)
		print("balance_changed", GlobalValues.hair_balls_total)
		print("=== PURCHASE COMPLETED ===\n")
		
		return true
	else:
		print("✗ PURCHASE DENIED - Insufficient funds")
		print("=== PURCHASE FAILED ===\n")
	
	return false

# Comprar múltiples unidades de un item
func purchase_bulk(item_index: int, amount: int) -> int:
	if item_index < 0 or item_index >= store_items.size():
		return 0
	
	var item = store_items[item_index]
	var cost = item.get_bulk_cost(amount)
	
	var purchased = 0
	
	if GlobalValues.hair_balls_total >= cost:
		# Comprar la cantidad completa
		GlobalValues.hair_balls_total -= cost
		item.quantity += amount
		purchased = amount
	else:
		# Comprar lo que se pueda
		purchased = item.try_bulk_purchase(GlobalValues.hair_balls_total, amount)
		if purchased > 0:
			cost = item.get_bulk_cost(purchased)
			GlobalValues.hair_balls_total -= cost
	
	if purchased > 0:
		_update_total_production()
		emit_signal("item_purchased", item)
		emit_signal("balance_changed", GlobalValues.hair_balls_total)
	
	return purchased

# Actualizar la producción total en el GameManager
func _update_total_production() -> void:
	var total_bps = Big_Number.new(0, 0)
	
	for item in store_items:
		total_bps = total_bps.add_another_big(item.get_total_production())  # ✅ Asignar resultado
	
	GlobalValues.hairs_balls_per_second = total_bps
	emit_signal("production_changed", total_bps)

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
	return GlobalValues.hair_balls_total.is_greater(item.get_current_cost())

# Guardar progreso de la tienda
func save_data() -> Dictionary:
	var items_data = []
	for item in store_items:
		items_data.append(item.to_dict())
	
	return {
		"items": items_data
	}

# Cargar progreso de la tienda
# Cargar progreso de la tienda
func load_data(data: Dictionary) -> void:
	if data.has("items"):
		var items_data = data["items"]
		for i in range(min(items_data.size(), store_items.size())):
			store_items[i].from_dict(items_data[i])
	
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
			print("🔄 Updated button ", button.item_name, " quantity: ", button.quantity)

# Crear botones de items
# Crear botones de items
func items_creation():
	# Ordenar store_items por store_index de menor a mayor
	store_items.sort_custom(func(a, b): return a.store_index < b.store_index)
	
	var index = 0 
	for item in store_items:
		print(item.item_name)
		var new_item = reference_item_button.instantiate()
		
		# Pasar todas las propiedades del Resource al Button
		new_item.store_index = int(index)
		new_item.item_name = item.item_name
		new_item.description = item.description
		new_item.icon = item.icon
		new_item.base_cost = item.base_cost
		new_item.base_production = item.base_production
		new_item.cost_multiplier = item.cost_multiplier
		new_item.amort_time = item.amort_time
		new_item.quantity = item.quantity
		
		# Asignar nombre y agregar al contenedor
		new_item.name = item.item_name
		v_box_container.add_child(new_item)
		
		# El botón manejará su propia visibilidad en _ready()
		
		index += 1

func _load_store_items() -> void:
	print("🔄 Loading items...")
	
	for item_path in ITEM_PATHS:
		var item = load(item_path) as StoreItem
		if item:
			var item_instance = item.duplicate()
			item_instance.quantity = 0
			store_items.append(item_instance)
			print("✅ Loaded: ", item.item_name)
		else:
			push_error("❌ Failed to load: " + item_path)
	
	print("📦 Total items loaded: ", store_items.size())

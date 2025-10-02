extends Node

# Señales para actualizar UI
signal item_purchased(item: StoreItem)
signal balance_changed(new_balance: float)
signal production_changed(new_bps: float)

# Catálogo de items (configura en el Inspector o por código)
@export var store_items: Array[StoreItem] = []

func _process(delta: float) -> void:
	if can_afford(0):
		purchase_item(0)
# Referencia al singleton de GameManager

func _ready() -> void:
	
	# Si no tienes items preconfigurados, créalos
	if store_items.is_empty():
		_create_default_items()
	
	# Actualizar producción total al iniciar
	_update_total_production()

# Crear items por defecto basados en Cookie Clicker
func _create_default_items() -> void:
	# Lengua Áspera (equivalente a Cursor)
	var tongue = StoreItem.new()
	tongue.item_name = "Lengua Áspera"
	tongue.description = "Una lengua rasposa que lame constantemente"
	tongue.base_cost = 15.0
	tongue.base_production = 0.1
	tongue.cost_multiplier = 1.15
	store_items.append(tongue)
	
	# Cepillo Mágico (equivalente a Grandma)
	var brush = StoreItem.new()
	brush.item_name = "Cepillo Mágico"
	brush.description = "Un cepillo que genera bolas de pelo por arte de magia"
	brush.base_cost = 100.0
	brush.base_production = 1.0
	brush.cost_multiplier = 1.15
	store_items.append(brush)
	
	# Pelotita de Estambre (equivalente a Farm)
	var yarn = StoreItem.new()
	yarn.item_name = "Pelotita de Estambre"
	yarn.description = "El gato juega y genera bolas de pelo juguetonamente"
	yarn.base_cost = 1100.0
	yarn.base_production = 8.0
	yarn.cost_multiplier = 1.15
	store_items.append(yarn)
	
	# Scratching Post Hipnótico (equivalente a Mine)
	var post = StoreItem.new()
	post.item_name = "Scratching Post Hipnótico"
	post.description = "Un poste rascador que hipnotiza al gato para producir más"
	post.base_cost = 12000.0
	post.base_production = 47.0
	post.cost_multiplier = 1.15
	store_items.append(post)

# Intentar comprar un item
func purchase_item(item_index: int) -> bool:
	if item_index < 0 or item_index >= store_items.size():
		return false
	
	var item = store_items[item_index]
	var cost = item.get_current_cost()
	
	# Verificar si hay suficiente balance
	if GlobalValues.hair_balls_total >= cost:
		# Realizar la compra
		GlobalValues.hair_balls_total -= cost
		item.quantity += 1
		
		# Actualizar producción total
		_update_total_production()
		
		# Emitir señales
		print("item_purchased", item)
		print("balance_changed", GlobalValues.hair_balls_total)
		
		return true
	
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
	var total_bps = 0.0
	
	for item in store_items:
		total_bps += item.get_total_production()
	
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
	return GlobalValues.hair_balls_total >= item.get_current_cost()

# Guardar progreso de la tienda
func save_data() -> Dictionary:
	var items_data = []
	for item in store_items:
		items_data.append(item.to_dict())
	
	return {
		"items": items_data
	}

# Cargar progreso de la tienda
func load_data(data: Dictionary) -> void:
	if data.has("items"):
		var items_data = data["items"]
		for i in range(min(items_data.size(), store_items.size())):
			store_items[i].from_dict(items_data[i])
	
	_update_total_production()

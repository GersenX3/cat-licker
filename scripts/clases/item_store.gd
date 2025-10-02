extends Resource
class_name StoreItem

# Propiedades base del item
@export var item_name: String = "Item"
@export var description: String = "Descripción del item"
@export var icon: Texture2D = null

# Economía (basado en Cookie Clicker)
@export var base_cost: float = 15.0  # Costo inicial
@export var base_production: float = 0.1  # BpS (Balls per Second)
@export var cost_multiplier: float = 1.15  # Factor exponencial (15% como Cookie Clicker)

# Estado actual
var quantity: int = 0  # Cantidad comprada

# Calculadora de costo exponencial
# Fórmula: C_n = C_1 * r^(n-1)
# Donde r = cost_multiplier y n = próxima cantidad
func get_current_cost() -> float:
	return base_cost * pow(cost_multiplier, quantity)

# Producción total de todas las unidades compradas
func get_total_production() -> float:
	return base_production * quantity

# Tiempo de amortización (en segundos)
# Cuánto tiempo tarda en recuperar la inversión
func get_payback_time() -> float:
	if base_production <= 0:
		return INF
	return get_current_cost() / base_production

# Comprar una unidad (retorna true si fue exitoso)
func try_purchase(current_balance: float) -> bool:
	var cost = get_current_cost()
	if current_balance >= cost:
		quantity += 1
		return true
	return false

# Obtener el costo para comprar múltiples unidades
# Suma geométrica: S = a * (r^n - 1) / (r - 1)
func get_bulk_cost(amount: int) -> float:
	if amount <= 0:
		return 0.0
	
	var r = cost_multiplier
	var current_cost = get_current_cost()
	
	# Suma de la serie geométrica
	if r == 1.0:
		return current_cost * amount
	else:
		return current_cost * (pow(r, amount) - 1.0) / (r - 1.0)

# Comprar múltiples unidades
func try_bulk_purchase(current_balance: float, amount: int) -> int:
	var purchased = 0
	var cost = get_bulk_cost(amount)
	
	if current_balance >= cost:
		quantity += amount
		return amount
	else:
		# Comprar la cantidad máxima posible
		for i in range(amount):
			if current_balance >= get_current_cost():
				quantity += 1
				current_balance -= get_current_cost()
				purchased += 1
			else:
				break
	
	return purchased

# Formatear números grandes para UI
static func format_number(value: float) -> String:
	if value < 1000:
		return str(snappedf(value, 0.1))
	elif value < 1_000_000:
		return str(snappedf(value / 1000.0, 0.1)) + "K"
	elif value < 1_000_000_000:
		return str(snappedf(value / 1_000_000.0, 0.1)) + "M"
	elif value < 1_000_000_000_000:
		return str(snappedf(value / 1_000_000_000.0, 0.1)) + "B"
	else:
		return str(snappedf(value / 1_000_000_000_000.0, 0.1)) + "T"

# Obtener info formateada para UI
func get_info_text() -> String:
	return "%s\nCosto: %s\nProducción: %s BpS\nPoseído: %d" % [
		item_name,
		format_number(get_current_cost()),
		format_number(base_production),
		quantity
	]

# Serialización para guardado
func to_dict() -> Dictionary:
	return {
		"item_name": item_name,
		"quantity": quantity
	}

# Deserialización desde guardado
func from_dict(data: Dictionary) -> void:
	if data.has("quantity"):
		quantity = data["quantity"]

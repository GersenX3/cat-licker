extends Resource
class_name StoreItem

# Propiedades base del item
@export var item_name: String = "Item"
@export var description: String = "Descripción del item"
@export var icon: Texture2D = null

# Economía (basado en Cookie Clicker)
@export var base_cost: Big_Number  # Costo inicial
@export var base_production: Big_Number  # BpS (Balls per Second)
@export var cost_multiplier: float = 1.15  # Factor exponencial (15% como Cookie Clicker)
@export var store_index: int = 0
@export var amort_time: Big_Number
# Estado actual
var quantity: int = 0  # Cantidad comprada

# Calculadora de costo exponencial
# Fórmula: C_n = C_1 * r^(n-1)
# Donde r = cost_multiplier y n = próxima cantidad
func get_current_cost() -> Big_Number:
	# costo = base_cost * (cost_multiplier ^ quantity)
	var exp_cost = pow(cost_multiplier, quantity)
	return base_cost.multiply(Big_Number.from_float(exp_cost))

# Producción total de todas las unidades compradas
func get_total_production() -> Big_Number:
	# producción = base_production * quantity
	return base_production.multiply(Big_Number.from_float(quantity))

# Tiempo de amortización (en segundos)
# Cuánto tiempo tarda en recuperar la inversión
func get_payback_time() -> float:
	# tiempo = costo / producción
	var prod = get_total_production()
	if prod.mantisa <= 0.0:
		return INF
	var cost = get_current_cost()
	# devolvemos como float (segundos), aproximado
	return (cost.mantisa * pow(10.0, cost.exp)) / (prod.mantisa * pow(10.0, prod.exp))

# Comprar una unidad (retorna true si fue exitoso)
func try_purchase(current_balance: float) -> bool:
	var cost = get_current_cost()
	if current_balance >= cost:
		quantity += 1
		return true
	return false

# Obtener el costo para comprar múltiples unidades
# Suma geométrica: S = a * (r^n - 1) / (r - 1)
func get_bulk_cost(amount: int) -> Big_Number:
	if amount <= 0:
		return Big_Number.new(0.0, 0)
	
	var r = cost_multiplier
	var current_cost = get_current_cost()
	
	# Fórmula de suma geométrica: S = a * (r^n - 1) / (r - 1)
	if r == 1.0:
		return current_cost.multiply(Big_Number.from_float(amount))
	else:
		var numerator = pow(r, amount) - 1.0
		var denominator = r - 1.0
		var factor = numerator / denominator
		return current_cost.multiply(Big_Number.from_float(factor))

# Comprar múltiples unidades
func try_bulk_purchase(current_balance: Big_Number, amount: int) -> int:
	var purchased = 0
	var total_cost = get_bulk_cost(amount)
	
	# Si alcanza para todas las unidades
	if current_balance.is_greater(total_cost) or not total_cost.is_greater(current_balance):
		quantity += amount
		return amount
	else:
		# Comprar la cantidad máxima posible una por una
		for i in range(amount):
			var cost = get_current_cost()
			if current_balance.is_greater(cost) or not cost.is_greater(current_balance):
				quantity += 1
				# restamos balance = balance - cost
				current_balance = Big_Number.from_float(
					(current_balance.mantisa * pow(10.0, current_balance.exp)) -
					(cost.mantisa * pow(10.0, cost.exp))
				)
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

func get_info_text() -> String:
	return "%s\nCosto: %s\nProducción: %s BpS\nPoseído: %d" % [
		item_name,
		get_current_cost().to_readable_string(),
		get_total_production().to_readable_string(),
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

extends Resource
class_name Big_Number

@export var mantisa: float
@export var exponential: int

#EXAMPLES
#var one = Big_Number.new(1.0, 0)         # 1
#var ten = Big_Number.new(1.0, 1)         # 1 × 10^1 = 10
#var million = Big_Number.new(1.0, 6)     # 1 × 10^6 = 1,000,000

# Constructor
func _init(m: float = 0.0, e: int = 0):
	mantisa = m
	exponential = e
	_normalize()

# Normaliza el número (mantisa siempre < 10)
# Normaliza el número (mantisa siempre < 10)
func _normalize() -> void:
	# Si la mantisa es cero, resetear exponente
	if mantisa == 0.0:
		exponential = 0
		return
	
	while mantisa >= 10.0:
		mantisa /= 10.0
		exponential += 1
	while mantisa > 0 and mantisa < 1.0:
		mantisa *= 10.0
		exponential -= 1
# Convierte un float a Big_Number
static func from_float(value: float) -> Big_Number:
	if value == 0.0:
		return Big_Number.new(0.0, 0)
	@warning_ignore("shadowed_variable")
	var exponential = int(floor(log(value) / log(10))) # log base 10
	@warning_ignore("shadowed_variable")
	var mantisa = value / pow(10.0, exponential)
	return Big_Number.new(mantisa, exponential)

# Multiplicación
func multiply(other: Big_Number) -> Big_Number:
	return Big_Number.new(mantisa * other.mantisa, exponential + other.exponential)

# Suma
func add_another_big(other: Big_Number) -> Big_Number:
	# Igualar exponentialonentes
	if exponential == other.exponential:
		return Big_Number.new(mantisa + other.mantisa, exponential)
	elif exponential > other.exponential:
		var diff = exponential - other.exponential
		if diff > 6: # demasiado grande, gana el mayor
			return self
		var new_m = mantisa + other.mantisa / pow(10.0, diff)
		return Big_Number.new(new_m, exponential)
	else:
		var diff = other.exponential - exponential
		if diff > 6:
			return other
		var new_m = mantisa / pow(10.0, diff) + other.mantisa
		return Big_Number.new(new_m, other.exponential)

# Resta
func subtract(other: Big_Number) -> Big_Number:
	if exponential == other.exponential:
		var result = mantisa - other.mantisa
		if result < 0:
			return Big_Number.new(0.0, 0) # No permitir negativos
		return Big_Number.new(result, exponential)
	elif exponential > other.exponential:
		var diff = exponential - other.exponential
		if diff > 6:
			return self # El otro es insignificante
		var new_m = mantisa - other.mantisa / pow(10.0, diff)
		if new_m < 0:
			return Big_Number.new(0.0, 0)
		return Big_Number.new(new_m, exponential)
	else:
		# other es mayor, resultado sería negativo
		return Big_Number.new(0.0, 0)

# ==================== OPERADORES BOOLEANOS ====================

# Mayor que (>)
func is_greater(other: Big_Number) -> bool:
	if exponential == other.exponential:
		return mantisa > other.mantisa
	return exponential > other.exponential

# Mayor o igual que (>=)
func is_greater_or_equal(other: Big_Number) -> bool:
	if exponential == other.exponential:
		return mantisa >= other.mantisa
	return exponential > other.exponential

# Menor que (<)
func is_less(other: Big_Number) -> bool:
	if exponential == other.exponential:
		return mantisa < other.mantisa
	return exponential < other.exponential

# Menor o igual que (<=)
func is_less_or_equal(other: Big_Number) -> bool:
	if exponential == other.exponential:
		return mantisa <= other.mantisa
	return exponential < other.exponential

# Igual a (==)
func is_equal(other: Big_Number) -> bool:
	return exponential == other.exponential and is_equal_approx(mantisa, other.mantisa)

# Diferente de (!=)
func is_not_equal(other: Big_Number) -> bool:
	return not is_equal(other)

# Verificar si es cero
func is_zero() -> bool:
	return mantisa == 0.0 or exponential < -300 # Prácticamente cero

# Verificar si es positivo
func is_positive() -> bool:
	return mantisa > 0.0 and exponential >= 0

# ==================== UTILIDADES ADICIONALES ====================

# Comparar con float directamente
func is_greater_than_float(value: float) -> bool:
	return is_greater(Big_Number.from_float(value))

func is_less_than_float(value: float) -> bool:
	return is_less(Big_Number.from_float(value))

func is_greater_or_equal_float(value: float) -> bool:
	return is_greater_or_equal(Big_Number.from_float(value))

func is_less_or_equal_float(value: float) -> bool:
	return is_less_or_equal(Big_Number.from_float(value))

# Convertir a float (con pérdida de precisión si es muy grande)
func to_float() -> float:
	if exponential > 308: # Límite de float64
		return INF
	if exponential < -308:
		return 0.0
	return mantisa * pow(10.0, exponential)

# Formato legible (renombrado para no chocar con Object.to_string)
func to_readable_string() -> String:
	# Para números menores a 1000, mostrar con decimales
	if exponential < 3:
		var value = mantisa * pow(10.0, exponential)
		if value < 10:
			return "%.1f" % value  # 0.10, 5.67, etc.
		elif value < 100:
			return "%.1f" % value  # 12.5, 99.9, etc.
		else:
			return "%.0f" % value  # 100, 999, etc.
	
	var suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
		"Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod"]  # hasta 10^63 aprox
	var group = int(floor(exponential / 3.0))
	
	if group >= 0 and group < suffixes.size():
		var scaled = mantisa * pow(10.0, exponential % 3)
		if scaled < 10 and group > 0:
			return "%.2f%s" % [scaled, suffixes[group]]
		elif scaled < 100 and group > 0:
			return "%.1f%s" % [scaled, suffixes[group]]
		else:
			return "%.0f%s" % [scaled, suffixes[group]]
	else:
		# Si ya no hay sufijo → notación científica
		return "%.2fe%d" % [mantisa, exponential]

# Clonar el número
func duplicate_big() -> Big_Number:
	return Big_Number.new(mantisa, exponential)

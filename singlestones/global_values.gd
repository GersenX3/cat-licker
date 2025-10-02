extends Node

var hair_balls_total: float = 0.0 # Es mejor usar 'float' para acumulación de tiempo
var hairs_balls_per_second: float = 0.0 # Ejemplo de una tasa por segundo

func _process(delta: float) -> void:
	# Incrementa el total usando la tasa multiplicada por el tiempo (delta)
	hair_balls_total += hairs_balls_per_second * delta
	#hairs_balls_per_second += hairs_balls_per_second
	# Puedes usar 'print' para ver la acumulación y el delta
	# print("Delta: ", delta, " | Total: ", hair_balls_total)
	pass

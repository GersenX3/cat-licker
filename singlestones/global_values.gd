extends Node

var hair_balls_total = Big_Number.new(0,0) # Es mejor usar 'float' para acumulación de tiempo
var hairs_balls_per_second = Big_Number.new(1,10) # Ejemplo de una tasa por segundo
var click_value = Big_Number.new(1,0)

func _process(delta: float) -> void:
	# Multiplica mantisa por delta, mantiene exponente
	var increment_mantisa = hairs_balls_per_second.mantisa * delta
	var increment = Big_Number.new(increment_mantisa, hairs_balls_per_second.exponential)
	
	# Suma al total
	hair_balls_total = hair_balls_total.add_another_big(increment)
	
	# Debug cada segundo para no saturar consola
	if Engine.get_frames_drawn() % 60 == 0:
		print("TOTAL: " + hair_balls_total.to_readable_string() + 
			  " | BpS: " + hairs_balls_per_second.to_readable_string())

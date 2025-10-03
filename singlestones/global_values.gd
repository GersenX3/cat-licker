extends Node

var hair_balls_total = Big_Number.new(0,0)
var hairs_balls_per_second = Big_Number.new(0,0)
var click_value = Big_Number.new(1,0)

func _ready() -> void:
	print("=== GLOBAL VALUES INITIALIZED ===")
	print("hair_balls_total: ", hair_balls_total.to_readable_string())
	print("hairs_balls_per_second: ", hairs_balls_per_second.to_readable_string())
	print("click_value: ", click_value.to_readable_string())

func _process(_delta: float) -> void:
	# Multiplica mantisa por delta, mantiene exponente
	var increment_mantisa = hairs_balls_per_second.mantisa * _delta
	var increment = Big_Number.new(increment_mantisa, hairs_balls_per_second.exponential)
	
	# Suma al total
	hair_balls_total = hair_balls_total.add_another_big(increment)
	#debug()

func debug():
	if Engine.get_frames_drawn() % 60 == 0:
		print("TOTAL: " + hair_balls_total.to_readable_string() + 
			  " | BpS: " + hairs_balls_per_second.to_readable_string())

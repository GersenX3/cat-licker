extends Control

# main.gd
func _ready() -> void:
	Store.initialize()  # ← la escena le dice al singleton que (re)arranque

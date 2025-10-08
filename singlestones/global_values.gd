extends Node

var hair_balls_total = Big_Number.new(0,0)
var hairs_balls_per_second = Big_Number.new(0,0)
var click_value = Big_Number.new(1,0)

func _ready() -> void:
	if OS.has_feature("web"):
		   # Espera interacción del usuario
		await get_tree().create_timer(0.1).timeout
	print("=== GLOBAL VALUES INITIALIZED ===")
	print("hair_balls_total: ", hair_balls_total.to_readable_string())
	print("hairs_balls_per_second: ", hairs_balls_per_second.to_readable_string())
	print("click_value: ", click_value.to_readable_string())
	
	# Desactivar clip en todos los RichTextLabel
	disable_clip_on_all_rich_labels()
	#MusicManager.play_song("res://assets/music/Intro.wav", 0, 0)

func _process(_delta: float) -> void:
	# Multiplica mantisa por delta, mantiene exponente
	var increment_mantisa = hairs_balls_per_second.mantisa * _delta# * 128 * 128 * 128
	var increment = Big_Number.new(increment_mantisa, hairs_balls_per_second.exponential)
	
	# Suma al total
	hair_balls_total = hair_balls_total.add_another_big(increment)
	#debug()

func debug():
	if Engine.get_frames_drawn() % 60 == 0:
		print("TOTAL: " + hair_balls_total.to_readable_string() + 
			  " | BpS: " + hairs_balls_per_second.to_readable_string())

# Buscar todos los RichTextLabel y desactivar clip_contents
func disable_clip_on_all_rich_labels() -> void:
	var root = get_tree().root
	_recursive_disable_clip(root)
	print("Clip desactivado en todos los RichTextLabel")

# Función recursiva para recorrer todos los nodos
func _recursive_disable_clip(node: Node) -> void:
	# Si el nodo es un RichTextLabel, desactivar clip
	if node is RichTextLabel:
		node.clip_contents = false
		print("Clip desactivado en: ", node.name)
	
	# Recorrer todos los hijos
	for child in node.get_children():
		_recursive_disable_clip(child)

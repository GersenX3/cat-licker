extends Button

# Propiedades base del item
var item_name: String = "Item"
var description: String = "Descripción del item"
#var icon: Texture2D = null

# Economía (basado en Cookie Clicker)
var base_cost: Big_Number  # Costo inicial
var base_production: Big_Number  # BpS (Balls per Second)
var cost_multiplier: float = 1.15  # Factor exponencial (15% como Cookie Clicker)
var store_index: int = 0
var amort_time: Big_Number
# Estado actual
var quantity: int = 0  # Cantidad comprada

func _ready() -> void:
	self.text = str(self.name)

func _on_pressed() -> void:
	print(self.text)
	Store.purchase_item(self.store_index)
	

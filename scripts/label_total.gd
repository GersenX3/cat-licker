extends Label

func _process(_delta: float) -> void:
	if self.name != "total":
		self.text = GlobalValues.hairs_balls_per_second.to_readable_string()
	else :
		self.text = GlobalValues.hair_balls_total.to_readable_string()

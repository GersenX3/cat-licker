extends Label

func _process(delta: float) -> void:
	if self.name != "total":
		self.text = format_number(GlobalValues.hairs_balls_per_second)
	else :
		self.text = format_number(GlobalValues.hair_balls_total)


func format_number(value: float) -> String:
	var suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
		"Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod"]  # hasta 10^63 aprox
	var i = 0
	
	# Divide hasta que el valor sea legible o se acaben los sufijos
	while value >= 1000.0 and i < suffixes.size() - 1:
		value /= 1000.0
		i += 1
	
	# Si se acabaron los sufijos → usar notación científica
	if value >= 1000.0:
		return str("%.2e" % GlobalValues.hair_balls_total)
	
	# Formato bonito con decimales
	if value < 10 and i > 0:
		return str("%.2f" % value) + suffixes[i]
	elif value < 100 and i > 0:
		return str("%.1f" % value) + suffixes[i]
	else:
		return str(int(value)) + suffixes[i]

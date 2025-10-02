extends Button


func _on_pressed() -> void:
	GlobalValues.hair_balls_total = GlobalValues.hair_balls_total.add_another_big(GlobalValues.click_value)
	print(GlobalValues.click_value.to_readable_string())
	print(GlobalValues.hair_balls_total.to_readable_string())

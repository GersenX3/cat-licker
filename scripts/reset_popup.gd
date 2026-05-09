extends Control

@onready var confirm_btn: Button = $CenterContainer/VBoxContainer/HBoxContainer/ConfirmBtn
@onready var countdown_label: Label = $CenterContainer/VBoxContainer/Countdown

var _seconds_left: int = 5

func _ready() -> void:
	confirm_btn.disabled = true
	_tick()

func _tick() -> void:
	countdown_label.text = str(_seconds_left)
	if _seconds_left <= 0:
		confirm_btn.disabled = false
		return
	_seconds_left -= 1
	await get_tree().create_timer(1.0).timeout
	_tick()

# Tu botón de confirmación
func _on_confirm_btn_pressed() -> void:
	GlobalValues.delete_save()
	Store.reset()
	get_tree().reload_current_scene()
	# initialize() se llama solo desde main._ready() al terminar el reload
	

func _on_cancel_btn_pressed() -> void:
	queue_free()

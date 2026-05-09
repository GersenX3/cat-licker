extends ScrollContainer

var _dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO
var _scroll_start: Vector2 = Vector2.ZERO
var _drag_confirmed: bool = false
const DRAG_THRESHOLD: float = 8.0

func _input(event: InputEvent) -> void:
	if not get_global_rect().has_point(get_global_mouse_position()):
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_confirmed = false
			_drag_start = event.position
			_scroll_start = Vector2(scroll_horizontal, scroll_vertical)
		else:
			_dragging = false
			# ✅ Si hubo drag, consumir el release para que no llegue a los hijos
			if _drag_confirmed:
				get_viewport().set_input_as_handled()
			_drag_confirmed = false

	elif event is InputEventMouseMotion and _dragging:
		var delta = event.position - _drag_start
		if delta.length() > DRAG_THRESHOLD:
			_drag_confirmed = true

		if _drag_confirmed:
			get_viewport().set_input_as_handled()
			scroll_horizontal = int(_scroll_start.x - delta.x)
			scroll_vertical   = int(_scroll_start.y - delta.y)

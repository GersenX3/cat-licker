extends AnimatedSprite2D

@export var tooltip_size: Vector2 = Vector2(64, 64)
@export var texto: String = "TOOLTIP"
@export var anim_name: String = "TOOLTIP" # Nombre de la animación que se ejecutará
@export var event_name: String = "TOOLTIP" # Nombre del evento al que se suscribe
@export var sound_path: String = "Path"

func _ready() -> void:
	# Crear el control de tooltip
	var control = Control.new()
	control.mouse_filter = Control.MOUSE_FILTER_PASS
	control.tooltip_text = texto
	control.custom_minimum_size = tooltip_size
	control.size = tooltip_size
	control.position = -tooltip_size / 2
	add_child(control)

	# Suscripción dinámica al evento definido en event_name
	if EventBus.has_method("subscribe"):
		EventBus.subscribe(event_name, _on_event_triggered, false)
	else:
		push_error("EventBus no tiene el método 'subscribe' o no está inicializado.")

func _on_event_triggered(_args) -> void:
	self.visible = true
	MusicManager.play_sound(sound_path, 0.5, false, 1,Vector2.ZERO)
	if sprite_frames and sprite_frames.has_animation(anim_name):
		self.play(anim_name)
	else:
		push_warning("No existe la animación '%s' en este AnimatedSprite2D." % anim_name)

func _on_animation_finished() -> void:
	# Vuelve a 'default' si la animación terminada es la configurada
	if animation == anim_name and sprite_frames.has_animation("default"):
		self.play("default")

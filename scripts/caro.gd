extends AnimatedSprite2D

@export var event_names: Array[String] = ["despertar", "!lamer", "sacudirse"]

func _ready() -> void:
	for raw_name in event_names:
		var one_shot := false
		var name := raw_name

		# Si empieza con "!", se suscribe una sola vez
		if raw_name.begins_with("!"):
			name = raw_name.substr(1, raw_name.length() - 1)
			one_shot = true

		EventBus.subscribe(name, func(anim_name: String):
			_on_event_triggered(anim_name)
			if one_shot:
				EventBus.unsubscribe(name, _on_event_triggered)
		, true)

func _on_event_triggered(anim_name: String) -> void:
	if sprite_frames and sprite_frames.has_animation(anim_name):
		play(anim_name)
	else:
		push_warning("Animación '%s' no encontrada en %s" % [anim_name, name])

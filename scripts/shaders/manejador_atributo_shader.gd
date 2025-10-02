extends ColorRect

var _active_tweens: Dictionary = {}

func animate_uniform(uniform_name: String, start_value: float, duration: float, end_value: float) -> void:
	# Verificar que el uniform existe
	#if not material is ShaderMaterial:
		#push_error("El nodo no tiene un ShaderMaterial asignado")
		#return
		#
	#if not material.shader.has_param(uniform_name):
		#push_error("El shader no tiene el uniform: " + uniform_name)
		#return

	# Cancelar tween anterior si existe
	if _active_tweens.has(uniform_name):
		var old_tween = _active_tweens[uniform_name]
		if old_tween and old_tween.is_valid():
			old_tween.kill()

	# Crear nuevo tween
	var new_tween = create_tween()
	new_tween.set_ease(Tween.EASE_IN_OUT)
	new_tween.set_trans(Tween.TRANS_SINE)
	
	material.set_shader_parameter(uniform_name, start_value)
	new_tween.tween_method(
		_set_uniform.bind(uniform_name),
		start_value,
		end_value,
		duration
	)
	
	# Guardar referencia y configurar limpieza automática
	_active_tweens[uniform_name] = new_tween
	new_tween.finished.connect(
		func(): _active_tweens.erase(uniform_name),
		CONNECT_ONE_SHOT
	)

func _set_uniform(value: float, uniform_name: String) -> void:
	material.set_shader_parameter(uniform_name, value)

# Ejemplo de uso
func start_chaos_effect():
	# Animar 'chaos' de 0 a 32 en 3 segundos
	animate_uniform("chaos", 0.0, 3.0, 32.0)
	
	# Animar 'radius' de 0.1 a 0.8 en 2 segundos con delay
	await get_tree().create_timer(1.0).timeout
	animate_uniform("radius", 0.1, 2.0, 0.8)
	
	# Animar 'attenuation' con diferentes valores
	await get_tree().create_timer(3.0).timeout
	animate_uniform("attenuation", 1.0, 1.5, 5.0)

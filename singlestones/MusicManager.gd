extends Node

# Configuración de volumen y transiciones
const DEFAULT_FADE_TIME: float = 1.0
const MIN_DB: float = -30.0  # Volumen mínimo para fades
const DEFAULT_VOLUME: float = 0.4  # Volumen inicial (0.0 a 1.0)
const DEFAULT_PITCH: float = 1.0   # Tono inicial (1.0 = normal)

var music_player: AudioStreamPlayer
var current_song: String = ""
var target_volume: float = linear_to_db(DEFAULT_VOLUME)
var transition_tween: Tween

func _ready():
	# Crear el reproductor de música automáticamente
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)
	
	# Configuración inicial
	music_player.volume_db = MIN_DB
	music_player.pitch_scale = DEFAULT_PITCH
	music_player.bus = "Music"
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS  # Seguir sonando en pausa
	
	# Establecer volumen inicial
	set_volume(DEFAULT_VOLUME)

# Reproduce una canción con transición suave
func play_song(song_path: String, fade_time: float = DEFAULT_FADE_TIME, force_restart: bool = false):
	# Misma canción y ya está sonando
	if song_path == current_song && music_player.playing && !force_restart:
		return
	
	# Nueva canción o reinicio forzado
	current_song = song_path
	
	var stream = load(song_path)
	if not stream:
		push_error("Canción no encontrada: " + song_path)
		return
	
	# Detener transiciones previas
	_cleanup_tweens()
	
	if music_player.playing:
		# Fade out -> Cambio -> Fade in
		transition_tween = create_tween().set_parallel(false)
		transition_tween.tween_property(music_player, "volume_db", MIN_DB, fade_time)
		transition_tween.tween_callback(_switch_song.bind(stream))
		transition_tween.tween_property(music_player, "volume_db", target_volume, fade_time)
	else:
		# Reproducción directa con fade in
		_switch_song(stream)
		transition_tween = create_tween()
		transition_tween.tween_property(music_player, "volume_db", target_volume, fade_time)

# Detiene la música con fade out
func stop_song(fade_time: float = DEFAULT_FADE_TIME):
	_cleanup_tweens()
	transition_tween = create_tween()
	transition_tween.tween_property(music_player, "volume_db", MIN_DB, fade_time)
	transition_tween.tween_callback(_stop_player)

# Cambia a una nueva pista inmediatamente
func _switch_song(stream: AudioStream):
	music_player.stream = stream
	music_player.play()
	music_player.volume_db = MIN_DB  # Reset para fade in

# Detiene el reproductor completamente
func _stop_player():
	music_player.stop()
	current_song = ""

# Ajusta el volumen principal (0.0 a 1.0)
func set_volume(volume: float):
	target_volume = linear_to_db(clamp(volume, 0.0, 1.0))
	if not transition_tween or not transition_tween.is_valid():
		music_player.volume_db = target_volume

# Ajusta el tono/pitch (0.5 a 2.0)
func set_pitch(pitch: float):
	music_player.pitch_scale = clamp(pitch, 0.5, 2.0)

# Resetea el tono a su valor por defecto
func reset_pitch():
	set_pitch(DEFAULT_PITCH)

# Obtiene el volumen actual (0.0 a 1.0)
func get_volume() -> float:
	return db_to_linear(music_player.volume_db)

# Obtiene el pitch actual
func get_pitch() -> float:
	return music_player.pitch_scale

# Limpia tweens existentes
func _cleanup_tweens():
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()

# Reproduce un efecto de sonido
func play_sound(sound_path: String, volume: float = 1.0, positional: bool = false, 
			   pitch: float = 1.0, position: Vector2 = Vector2.ZERO):
	var sound
	
	if positional:
		sound = AudioStreamPlayer2D.new()
		# Asignar posición si se proporcionó
		if position != Vector2.ZERO:
			sound.global_position = position
		else:
			# Opcional: asignar posición del jugador si no se especifica
			# (comenta si prefieres siempre posición específica)
			var player = get_tree().get_first_node_in_group("player")
			if player:
				sound.global_position = player.global_position
	else:
		sound = AudioStreamPlayer.new()
	
	# Agregar a la escena actual para contexto espacial
	get_tree().root.get_node("MusicManager").add_child(sound)
	
	sound.stream = load(sound_path)
	sound.volume_db = linear_to_db(volume)
	sound.pitch_scale = clamp(pitch, 0.5, 2.0)
	sound.bus = "SFX"
	sound.play()
	sound.finished.connect(sound.queue_free)

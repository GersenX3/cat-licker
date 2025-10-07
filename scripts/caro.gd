extends AnimatedSprite2D

@export var idle_anim: String = "idle"
@export var wake_anim: String = "despertando"
@export var lick_anim: String = "lamiendo"

var has_woken_up := false
var is_playing_click_anim := false

func _ready() -> void:
	# Animación automática inicial
	if sprite_frames and sprite_frames.has_animation(animation):
		play(animation)

	# Escuchar eventos del botón
	EventBus.subscribe("button_click", _on_button_clicked, false)

	# Cuando termina cualquier animación
	connect("animation_finished", Callable(self, "_on_animation_finished"))


func _on_button_clicked(_anim_name: String) -> void:
	if not has_woken_up:
		has_woken_up = true
		is_playing_click_anim = true
		play(wake_anim)
	else:
		is_playing_click_anim = true
		play(lick_anim)


func _on_animation_finished() -> void:
	# Si la animación terminó y no se está clickeando, vuelve a idle
	if is_playing_click_anim:
		is_playing_click_anim = false
		play(idle_anim)

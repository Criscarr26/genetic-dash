extends Node2D

# Script raíz de cada nivel: reproduce la música en bucle y
# permite reiniciar (R) o volver al menú (Esc).

@onready var musica: AudioStreamPlayer = $Musica
@onready var jugador: CharacterBody2D = $Jugador


func _ready() -> void:
	if musica.stream != null:
		# Los .ogg no vienen con loop activado por defecto.
		if musica.stream is AudioStreamOggVorbis:
			musica.stream.loop = true
		musica.play()


func _unhandled_input(event: InputEvent) -> void:
	# No interrumpir la transición de victoria.
	if jugador != null and jugador.nivel_completado:
		return
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Escenas/Menu.tscn")
	elif event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()

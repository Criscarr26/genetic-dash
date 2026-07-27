extends Node2D

# Script raíz de cada nivel: reproduce la música en bucle y
# permite reiniciar (R) o volver al menú (Esc).

## En modo IA el nivel es solo el escenario: quien manda es el entrenador,
## que se queda con la cámara, retira al jugador humano y maneja las teclas.
var modo_ia := false

@onready var musica: AudioStreamPlayer = $Musica
@onready var jugador: CharacterBody2D = $Jugador


func _ready() -> void:
	if musica.stream != null:
		# Los .ogg no vienen con loop activado por defecto.
		if musica.stream is AudioStreamOggVorbis:
			musica.stream.loop = true
		musica.play()


## La llama el entrenador justo después de instanciar el nivel.
func activar_modo_ia() -> void:
	modo_ia = true
	# Con la simulación acelerada la música sonaría a chipmunk.
	musica.stop()


func _unhandled_input(event: InputEvent) -> void:
	if modo_ia:
		return
	# No interrumpir la transición de victoria.
	if is_instance_valid(jugador) and jugador.nivel_completado:
		return
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Escenas/Menu.tscn")
	elif event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()

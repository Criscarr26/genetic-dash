extends Area2D

# Un mismo script para los tres portales del juego.
enum Tipo { NAVE, NORMAL, META }

@export var tipo: Tipo = Tipo.NAVE
# Solo para el portal de META: escena que se carga al completar el nivel.
@export_file("*.tscn") var siguiente_escena: String = ""

@onready var snd_portal: AudioStreamPlayer = $SndPortal

var _activado := false


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player") or body.muerto:
		return

	match tipo:
		Tipo.NAVE:
			body.activar_nave(true)
			_sonar(body)
		Tipo.NORMAL:
			body.activar_nave(false)
			_sonar(body)
		Tipo.META:
			body.ganar()
			_sonar(body)
			# Con varios bots corriendo, el primero en llegar no puede
			# arrastrar la escena entera al siguiente nivel: en modo IA es el
			# entrenador quien decide qué hacer cuando alguien completa.
			if not body.auto_reiniciar:
				return
			if _activado:
				return
			_activado = true
			await get_tree().create_timer(0.9).timeout
			if not is_inside_tree():
				return
			if siguiente_escena != "":
				get_tree().change_scene_to_file(siguiente_escena)


## El entrenador la llama al empezar cada generación.
func reiniciar() -> void:
	_activado = false


func _sonar(body: Node2D) -> void:
	if body is Jugador and body.silencioso:
		return
	if snd_portal.playing:
		return
	snd_portal.play()

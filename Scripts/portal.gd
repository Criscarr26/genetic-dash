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
			snd_portal.play()
		Tipo.NORMAL:
			body.activar_nave(false)
			snd_portal.play()
		Tipo.META:
			if _activado:
				return
			_activado = true
			body.ganar()
			snd_portal.play()
			await get_tree().create_timer(0.9).timeout
			if not is_inside_tree():
				return
			if siguiente_escena != "":
				get_tree().change_scene_to_file(siguiente_escena)

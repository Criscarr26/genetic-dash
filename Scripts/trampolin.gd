extends Area2D

# Impulso vertical del trampolín: bastante más fuerte que el salto normal (-640).
@export var fuerza_rebote: float = -1050.0

@onready var snd_rebote: AudioStreamPlayer = $SndRebote


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not body.muerto:
		body.velocity.y = fuerza_rebote
		snd_rebote.play()

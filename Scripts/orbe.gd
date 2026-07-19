extends Area2D

# Orbe de doble salto: si el jugador presiona saltar mientras la toca,
# recibe un impulso en el aire. Cada orbe se usa una sola vez.

var usado := false

@onready var sprite: Sprite2D = $Sprite2D


func disponible() -> bool:
	return not usado


func usar() -> void:
	usado = true
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.25)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.orbe_actual = self


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and body.orbe_actual == self:
		body.orbe_actual = null

extends Area2D

# Orbe de doble salto: si el jugador presiona saltar mientras la toca,
# recibe un impulso en el aire. Cada orbe se usa una sola vez... por jugador.
#
# El estado de "usada" es por cuerpo y no global: en modo IA hay decenas de
# bots recorriendo el nivel a la vez, y si el primero en tocarla la apagara
# para todos, los demás quedarían evaluados sobre un nivel distinto.

## IDs de los cuerpos que ya la gastaron en este intento.
var _usada_por := {}

@onready var sprite: Sprite2D = $Sprite2D


func disponible(cuerpo: Node2D) -> bool:
	return not _usada_por.has(cuerpo.get_instance_id())


func usar(cuerpo: Node2D) -> void:
	_usada_por[cuerpo.get_instance_id()] = true
	# El apagado visual solo tiene sentido cuando hay un único jugador.
	if cuerpo is Jugador and cuerpo.piloto == Jugador.Piloto.HUMANO:
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.25)


## El entrenador la llama al empezar cada generación.
func reiniciar() -> void:
	_usada_por.clear()
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.orbe_actual = self


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and body.orbe_actual == self:
		body.orbe_actual = null

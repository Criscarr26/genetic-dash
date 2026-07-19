extends Area2D

# Esta área es más pequeña que el cuerpo del jugador (32x32 contra 64x64)
# para que las muertes contra púas se sientan justas, como en Geometry Dash.


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Kill"):
		get_parent().morir()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Kill"):
		get_parent().morir()

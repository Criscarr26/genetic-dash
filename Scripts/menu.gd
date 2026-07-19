extends Control

@onready var musica: AudioStreamPlayer = $Musica


func _ready() -> void:
	if musica.stream != null:
		if musica.stream is AudioStreamOggVorbis:
			musica.stream.loop = true
		musica.play()


func _on_nivel_1_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/Nivel1.tscn")


func _on_nivel_2_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/Nivel2.tscn")


func _on_nivel_3_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/Nivel3.tscn")


func _on_salir_pressed() -> void:
	get_tree().quit()

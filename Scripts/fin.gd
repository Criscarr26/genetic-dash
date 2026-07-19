extends Control

@onready var musica: AudioStreamPlayer = $Musica


func _ready() -> void:
	if musica.stream != null:
		if musica.stream is AudioStreamOggVorbis:
			musica.stream.loop = true
		musica.play()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/Menu.tscn")

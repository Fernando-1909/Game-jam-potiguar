extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_iniciar_pressed() -> void:
	print("Iniciar pressionado")
	get_tree().change_scene_to_file("res://Main_Scene.tscn")

func _on_sair_pressed() -> void:
	print("Sair pressionado, jogo fechado!")
	get_tree().quit()

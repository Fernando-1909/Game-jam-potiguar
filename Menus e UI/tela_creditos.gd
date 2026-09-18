extends Control



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Sair"):
		get_tree().change_scene_to_file("res://Menus e UI/menu_principal.tscn")

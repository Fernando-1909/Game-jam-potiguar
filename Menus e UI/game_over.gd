extends Control

func _ready():
	self.hide()

func game_over():
	get_tree().paused = true
	self.show()

func _on_reiniciar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_sair_pressed() -> void:
	pass # Replace with function body.

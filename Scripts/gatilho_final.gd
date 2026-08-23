extends Area2D

@export_file("*.tscn") var cena_final: String = "res://final_cutscene.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Altere "Player" para o nome do nó do seu personagem ou verifique se está no grupo "player"
	if body.name == "Player" or body.is_in_group("player"):
		get_tree().change_scene_to_file(cena_final)

extends Control

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _on_iniciar_pressed() -> void:
	print("Iniciar pressionado -> Indo para a Cutscene Inicial")
	# Configura a cutscene para rodar no modo de introdução
	CutsceneTexto.modo_introducao = true
	# Ajuste o caminho da cena abaixo se o seu arquivo .tscn estiver em outra pasta
	get_tree().change_scene_to_file("res://Cenas do jogo/final_cutscene.tscn")

func _on_sair_pressed() -> void:
	print("Sair pressionado, jogo fechado!")
	get_tree().quit()

func _on_créditos_pressed() -> void:
	print("Indo para a tela de créditos")
	get_tree().change_scene_to_file("res://Menus e UI/tela_creditos.tscn")

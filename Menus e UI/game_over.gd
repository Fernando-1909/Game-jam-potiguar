extends CanvasLayer

# Altere este caminho no Inspetor para a sua cena de Menu Principal
@export_file("*.tscn") var cena_menu_inicial: String = "res://menu.tscn"

func _ready() -> void:
	# Garante que este nó continue processando inputs durante a pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Garante que fique oculto ao iniciar o jogo
	hide()

func game_over() -> void:
	show()
	get_tree().paused = true

func _on_reiniciar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_sair_pressed() -> void:
	get_tree().paused = false
	if cena_menu_inicial != "" and ResourceLoader.exists(cena_menu_inicial):
		get_tree().change_scene_to_file(cena_menu_inicial)
	else:
		push_error("Caminho do Menu Inicial inválido. Configure no Inspetor do GameOver!")

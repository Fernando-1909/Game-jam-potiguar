extends Area2D

@export_group("Gatilho do Boss")
@export var boss_node: Node2D

@export_group("Gatilho do Tutorial")
@export var tutorial_node: CanvasLayer

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not _e_player(body):
		return

	# Se a área tiver o nó do Tutorial associado, mostra ao entrar no quarto
	if is_instance_valid(tutorial_node) and tutorial_node.has_method("mostrar_tutorial"):
		tutorial_node.mostrar_tutorial()

	# Se a área tiver o nó do Boss associado, inicia a boss fight e se destrói
	if is_instance_valid(boss_node) and boss_node.has_method("iniciar_boss_fight"):
		body.set_physics_process(false)
		if "velocity" in body:
			body.velocity = Vector2.ZERO

		await get_tree().create_timer(1.0).timeout

		body.set_physics_process(true)
		boss_node.iniciar_boss_fight(body)
		
		queue_free()

func _on_body_exited(body: Node2D) -> void:
	if not _e_player(body):
		return

	# Se a área tiver o nó do Tutorial associado, esconde ao sair do quarto
	if is_instance_valid(tutorial_node) and tutorial_node.has_method("esconder_tutorial"):
		tutorial_node.esconder_tutorial()

func _e_player(node: Node) -> bool:
	return node.name == "Player" or node.is_in_group("player")

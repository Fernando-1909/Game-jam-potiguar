extends Area2D

@export var boss_node: Node2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and boss_node:
		# Paralisa o movimento do jogador temporariamente
		body.set_physics_process(false)
		body.velocity = Vector2.ZERO

		# Pausa dramatica de 1 segundo
		await get_tree().create_timer(1.0).timeout

		# Retoma a movimentacao do jogador e ativa a camera do boss
		body.set_physics_process(true)
		boss_node.iniciar_boss_fight(body)
		queue_free()

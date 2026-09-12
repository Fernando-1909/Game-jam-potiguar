extends Node2D

@export_group("Referências")
@export var boss_node: Node2D
@export var tutorial_node: CanvasLayer

@onready var area_quarto: Area2D = $AreaQuarto
@onready var area_boss: Area2D = $AreaBoss

func _ready() -> void:
	if is_instance_valid(area_quarto):
		area_quarto.body_entered.connect(_on_area_quarto_body_entered)
		area_quarto.body_exited.connect(_on_area_quarto_body_exited)

	if is_instance_valid(area_boss):
		area_boss.body_entered.connect(_on_area_boss_body_entered)

# --- CONTROLE DO TUTORIAL (ÁREA DO QUARTO) ---
func _on_area_quarto_body_entered(body: Node2D) -> void:
	if _e_player(body) and is_instance_valid(tutorial_node):
		if tutorial_node.has_method("mostrar_tutorial"):
			tutorial_node.mostrar_tutorial()

func _on_area_quarto_body_exited(body: Node2D) -> void:
	if _e_player(body) and is_instance_valid(tutorial_node):
		if tutorial_node.has_method("esconder_tutorial"):
			tutorial_node.esconder_tutorial()

# --- CONTROLE DO BOSS ---
func _on_area_boss_body_entered(body: Node2D) -> void:
	if _e_player(body) and is_instance_valid(boss_node):
		body.set_physics_process(false)
		if "velocity" in body:
			body.velocity = Vector2.ZERO

		await get_tree().create_timer(1.0).timeout

		body.set_physics_process(true)
		if boss_node.has_method("iniciar_boss_fight"):
			boss_node.iniciar_boss_fight(body)

		# Remove apenas o gatilho do boss para não repetir o evento
		area_boss.queue_free()

func _e_player(node: Node) -> bool:
	return node.name == "Player" or node.is_in_group("player")

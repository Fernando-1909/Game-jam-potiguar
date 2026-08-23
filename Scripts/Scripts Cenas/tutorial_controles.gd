extends CanvasLayer

@export var tempo_visivel: float = 5.0 # Tempo em segundos antes de começar a sumir
@export var tempo_fade: float = 1.0    # Duração da transição de transparência

@onready var panel_container: PanelContainer = $PanelContainer

func _ready() -> void:
	if panel_container:
		panel_container.modulate.a = 1.0 # Reseta a visibilidade do painel
	_iniciar_animacoes(self)
	_agendar_desaparecimento()

func _iniciar_animacoes(no_pai: Node) -> void:
	# Busca recursivamente todos os AnimatedSprite2D na hierarquia e ativa o play()
	for filho in no_pai.get_children():
		if filho is AnimatedSprite2D:
			filho.play("default")
		if filho.get_child_count() > 0:
			_iniciar_animacoes(filho)

func _agendar_desaparecimento() -> void:
	await get_tree().create_timer(tempo_visivel).timeout
	_sumir_gradualmente()

func _sumir_gradualmente() -> void:
	if not panel_container:
		queue_free()
		return

	var tween = create_tween()
	tween.tween_property(panel_container, "modulate:a", 0.0, tempo_fade)
	await tween.finished
	queue_free()

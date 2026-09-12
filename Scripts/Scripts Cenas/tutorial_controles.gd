extends CanvasLayer

@export var tempo_fade: float = 0.5 # Tempo de transição de entrada/saída em segundos

@onready var panel_container: PanelContainer = $PanelContainer

var tween: Tween

func _ready() -> void:
	_iniciar_animacoes(self)

func _iniciar_animacoes(no_pai: Node) -> void:
	for filho in no_pai.get_children():
		if filho is AnimatedSprite2D:
			filho.play("default")
		if filho.get_child_count() > 0:
			_iniciar_animacoes(filho)

func mostrar_tutorial() -> void:
	if not panel_container:
		return
	
	if tween and tween.is_running():
		tween.kill()
		
	show()
	tween = create_tween()
	tween.tween_property(panel_container, "modulate:a", 1.0, tempo_fade)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

func esconder_tutorial() -> void:
	if not panel_container:
		return
		
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.tween_property(panel_container, "modulate:a", 0.0, tempo_fade)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

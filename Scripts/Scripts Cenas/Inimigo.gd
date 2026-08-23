extends CharacterBody2D

@export var velocidade_perseguicao: float = 90.0
@export var raio_perseguicao: float = 250.0 # Distancia minima para comecar a perseguir
@export var permite_ser_derrotado: bool = false # FALSE para Fase 1 | TRUE para Fase 2

var player_ref: CharacterBody2D = null
var gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite: AnimatedSprite2D = $SpriteInimigo

func _ready() -> void:
	add_to_group("dano") # Para o Player detectar o contato de dano
	
	# Busca a referencia do Player na cena
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	else:
		player_ref = get_parent().get_node_or_null("Player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravidade * delta

	var esta_sonhando: bool = false
	if is_instance_valid(player_ref) and "esta_sonhando_player" in player_ref:
		esta_sonhando = player_ref.esta_sonhando_player

	# MUNDO REAL: Fica totalmente parado
	if not esta_sonhando:
		velocity.x = 0.0
		if sprite:
			sprite.play("Idle") if sprite.sprite_frames.has_animation("Idle") else sprite.stop()
		move_and_slide()
		return

	# MUNDO DOS SONHOS: Persegue o jogador se estiver dentro do alcance
	if is_instance_valid(player_ref):
		var distancia_x = player_ref.global_position.x - global_position.x
		
		# Verifica se o jogador ultrapassou o ponto / esta dentro da distancia
		if abs(distancia_x) <= raio_perseguicao:
			var direcao_x = sign(distancia_x)
			velocity.x = direcao_x * velocidade_perseguicao

			if sprite:
				sprite.play("Walk")
				sprite.flip_h = (direcao_x < 0)
		else:
			velocity.x = 0.0
			if sprite:
				sprite.play("Idle") if sprite.sprite_frames.has_animation("Idle") else sprite.stop()

	move_and_slide()

# Detecta o pulo do jogador no topo da cabeca
func _on_area_cabeca_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		# Se o jogador estiver caindo sobre o inimigo
		if body.velocity.y > 0:
			if permite_ser_derrotado:
				# Quica o jogador para cima e elimina o fantasma (Fase 2)
				body.velocity.y = -400.0
				queue_free()
			else:
				# Na Fase 1 o fantasma nao morre e o player toma dano normal no impacto
				if body.has_method("tomar_dano"):
					body.tomar_dano(33)

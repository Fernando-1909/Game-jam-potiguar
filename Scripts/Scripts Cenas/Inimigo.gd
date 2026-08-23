extends CharacterBody2D

@export var velocidade_perseguicao: float = 90.0
@export var raio_perseguicao: float = 250.0
@export var permite_ser_derrotado: bool = false
@export var sprite_original_olhando_esquerda: bool = true

# Velocidade do inimigo no estado normal
@export var velocidade_idle: float = 20.0

const ANIM_IDLE = "Idle"
const ANIM_TRANSFORMANDO = "TRANSformando"
const ANIM_TRANSFORMADO = "TRANSfomado"
const ANIM_DESTRANSFORMANDO = "desTRANSfomando"

var player_ref: CharacterBody2D = null
var gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var esta_sonhando_anterior: bool = false
var em_transicao_animacao: bool = false

# Direção do movimento lento no estado normal
var direcao_idle: float = 1.0

@onready var sprite: AnimatedSprite2D = $SpriteInimigo


func _ready() -> void:
	add_to_group("dano")

	if sprite:
		sprite.play(ANIM_IDLE)

	await get_tree().process_frame

	var players = get_tree().get_nodes_in_group("player")

	if players.size() > 0:
		player_ref = players[0]
	else:
		player_ref = get_parent().get_node_or_null("Player")


func _physics_process(delta: float) -> void:

	var esta_sonhando: bool = false

	if is_instance_valid(player_ref) and "esta_sonhando_player" in player_ref:
		esta_sonhando = player_ref.esta_sonhando_player


	# Detecta mudança de estado
	if esta_sonhando != esta_sonhando_anterior:
		esta_sonhando_anterior = esta_sonhando
		_tratar_transicao_estado(esta_sonhando)


	# =========================================================
	# TRANSIÇÃO
	# =========================================================

	if em_transicao_animacao:
		velocity = Vector2.ZERO

		# Mantém as colisões durante a transformação.
		move_and_slide()

		return


	# =========================================================
	# MUNDO NORMAL
	# =========================================================

	if not esta_sonhando:

		# Anda lentamente de um lado para o outro.
		velocity.x = direcao_idle * velocidade_idle

		# Inverte a direção quando bate em uma parede.
		if is_on_wall():
			direcao_idle *= -1.0
			velocity.x = direcao_idle * velocidade_idle

		# Gravidade normal.
		if not is_on_floor():
			velocity.y += gravidade * delta
		else:
			velocity.y = 0.0

		# Mantém a animação Idle.
		if sprite:
			if sprite.animation != ANIM_IDLE or not sprite.is_playing():
				sprite.play(ANIM_IDLE)

			_atualizar_espelhamento(direcao_idle)

		# Mantém colisão com chão e blocos.
		move_and_slide()

		return


	# =========================================================
	# MUNDO DOS SONHOS / TRANSFORMADO
	# =========================================================

	# No mundo dos sonhos não existe gravidade.
	velocity.y = 0.0

	if is_instance_valid(player_ref):

		var distancia_x = player_ref.global_position.x - global_position.x
		var distancia_y = player_ref.global_position.y - global_position.y

		var distancia = Vector2(
			distancia_x,
			distancia_y
		)

		if distancia.length() <= raio_perseguicao:

			# Faz o inimigo voar em direção ao player.
			if distancia.length() > 5.0:
				var direcao = distancia.normalized()

				velocity = direcao * velocidade_perseguicao
			else:
				velocity = Vector2.ZERO

			if sprite:
				if sprite.animation != ANIM_TRANSFORMADO or not sprite.is_playing():
					sprite.play(ANIM_TRANSFORMADO)

				_atualizar_espelhamento(velocity.x)

		else:
			velocity = Vector2.ZERO

			if sprite:
				if sprite.animation != ANIM_TRANSFORMADO or not sprite.is_playing():
					sprite.play(ANIM_TRANSFORMADO)

	# No sonho ele voa livremente.
	move_and_slide()


func _atualizar_espelhamento(direcao_x: float) -> void:
	if direcao_x == 0 or not sprite:
		return

	if sprite_original_olhando_esquerda:
		sprite.flip_h = (direcao_x > 0)
	else:
		sprite.flip_h = (direcao_x < 0)


func _tratar_transicao_estado(entrando_no_sonho: bool) -> void:
	em_transicao_animacao = true

	if entrando_no_sonho:

		if sprite and sprite.sprite_frames.has_animation(ANIM_TRANSFORMANDO):
			sprite.play(ANIM_TRANSFORMANDO)
			await sprite.animation_finished

		if sprite:
			sprite.play(ANIM_TRANSFORMADO)

	else:

		if sprite and sprite.sprite_frames.has_animation(ANIM_DESTRANSFORMANDO):
			sprite.play(ANIM_DESTRANSFORMANDO)
			await sprite.animation_finished

		if sprite:
			sprite.play(ANIM_IDLE)

		# Para completamente o movimento ao voltar
		# para o mundo normal.
		velocity = Vector2.ZERO

	em_transicao_animacao = false


func _on_area_cabeca_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":

		if body.velocity.y > 0:

			if permite_ser_derrotado:
				body.velocity.y = -400.0
				queue_free()

			else:
				if body.has_method("tomar_dano"):
					body.tomar_dano(33)

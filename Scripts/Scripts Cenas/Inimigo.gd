extends CharacterBody2D

@export var velocidade_perseguicao: float = 90.0
@export var raio_perseguicao: float = 250.0
@export var permite_ser_derrotado: bool = false
@export var sprite_original_olhando_esquerda: bool = true

# Parametros da patrulha no Mundo Real
@export var velocidade_patrulha: float = 40.0
@export var tempo_patrulha_min: float = 1.0
@export var tempo_patrulha_max: float = 3.0
@export var tempo_espera_min: float = 1.0
@export var tempo_espera_max: float = 2.5

const ANIM_IDLE = "Idle"
const ANIM_TRANSFORMANDO = "TRANSformando"
const ANIM_TRANSFORMADO = "TRANSfomado"
const ANIM_DESTRANSFORMANDO = "desTRANSfomando"

var player_ref: CharacterBody2D = null
var gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var esta_sonhando_anterior: bool = false
var em_transicao_animacao: bool = false

var direcao_patrulha: int = 0
var timer_patrulha: float = 0.0

@onready var sprite: AnimatedSprite2D = $SpriteInimigo

func _ready() -> void:
	add_to_group("dano")
	
	if sprite:
		sprite.play(ANIM_IDLE)

	_escolher_nova_acao_patrulha()

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

	if esta_sonhando != esta_sonhando_anterior:
		esta_sonhando_anterior = esta_sonhando
		_tratar_transicao_estado(esta_sonhando)

	if em_transicao_animacao:
		velocity.x = 0.0
		move_and_slide()
		return

	# ESTADO: MUNDO REAL (Movimento Aleatorio / Patrulha)
	if not esta_sonhando:
		timer_patrulha -= delta
		if timer_patrulha <= 0.0:
			_escolher_nova_acao_patrulha()

		if is_on_wall() and direcao_patrulha != 0:
			direcao_patrulha *= -1

		velocity.x = direcao_patrulha * velocidade_patrulha

		if sprite:
			# Garante que a animacao de Idle toque e continue em loop ativo
			if sprite.animation != ANIM_IDLE or not sprite.is_playing():
				sprite.play(ANIM_IDLE)
			_atualizar_espelhamento(direcao_patrulha)

		move_and_slide()
		return

	# ESTADO: MUNDO DOS SONHOS (Perseguição)
	if is_instance_valid(player_ref):
		var distancia_x = player_ref.global_position.x - global_position.x
		
		if abs(distancia_x) <= raio_perseguicao:
			var direcao_x = sign(distancia_x)
			velocity.x = direcao_x * velocidade_perseguicao

			if sprite:
				if sprite.animation != ANIM_TRANSFORMADO or not sprite.is_playing():
					sprite.play(ANIM_TRANSFORMADO)
				_atualizar_espelhamento(direcao_x)
		else:
			velocity.x = 0.0
			if sprite and (sprite.animation != ANIM_TRANSFORMADO or not sprite.is_playing()):
				sprite.play(ANIM_TRANSFORMADO)

	move_and_slide()

func _escolher_nova_acao_patrulha() -> void:
	var opçoes = [-1, 0, 1]
	direcao_patrulha = opçoes.pick_random()

	if direcao_patrulha == 0:
		timer_patrulha = randf_range(tempo_espera_min, tempo_espera_max)
	else:
		timer_patrulha = randf_range(tempo_patrulha_min, tempo_patrulha_max)

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
		if esta_sonhando_anterior:
			sprite.play(ANIM_TRANSFORMADO)
	else:
		if sprite and sprite.sprite_frames.has_animation(ANIM_DESTRANSFORMANDO):
			sprite.play(ANIM_DESTRANSFORMANDO)
			await sprite.animation_finished
		if not esta_sonhando_anterior:
			sprite.play(ANIM_IDLE)
			_escolher_nova_acao_patrulha()
			
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

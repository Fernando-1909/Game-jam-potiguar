extends Node2D

@export var velocidade_chase: float = 120.0
var ativo: bool = false
var mao_esquerda_vez: bool = true
var player_ref: CharacterBody2D = null

@onready var camera: Camera2D = $CameraBoss
@onready var sprite_boss = $SpriteBoss
@onready var marker_esq: Marker2D = $MarkerMaoEsq
@onready var marker_dir: Marker2D = $MarkerMaoDir
@onready var mao_esq: Area2D = $MaoEsquerda
@onready var mao_dir: Area2D = $MaoDireita
@onready var timer_ataque: Timer = $TimerAtaque

func _ready() -> void:
	hide()
	set_process(false)
	set_physics_process(false)

	# Associa os marcadores e posiciona imediatamente no global space
	if is_instance_valid(mao_esq) and is_instance_valid(marker_esq):
		mao_esq.posicao_origem = marker_esq
		mao_esq.nome_animacao = "MaoEsquerda"
		mao_esq.global_position = marker_esq.global_position

	if is_instance_valid(mao_dir) and is_instance_valid(marker_dir):
		mao_dir.posicao_origem = marker_dir
		mao_dir.nome_animacao = "MaoDireita"
		mao_dir.global_position = marker_dir.global_position

	if timer_ataque:
		if timer_ataque.timeout.is_connected(_executar_ataque):
			timer_ataque.timeout.disconnect(_executar_ataque)
		timer_ataque.timeout.connect(_executar_ataque)

func iniciar_boss_fight(player: CharacterBody2D) -> void:
	player_ref = player
	ativo = true

	show()
	set_process(true)
	set_physics_process(true)

	if sprite_boss is AnimatedSprite2D:
		sprite_boss.play()

	if is_instance_valid(mao_esq) and mao_esq.has_method("ativar_mao"):
		mao_esq.ativar_mao()
	if is_instance_valid(mao_dir) and mao_dir.has_method("ativar_mao"):
		mao_dir.ativar_mao()

	if camera:
		camera.global_position = player.global_position
		camera.make_current()

	if timer_ataque:
		timer_ataque.start()

func _process(delta: float) -> void:
	if not ativo:
		return

	position.x += velocidade_chase * delta

	if camera and is_instance_valid(player_ref):
		var x_alvo = max(camera.global_position.x + (velocidade_chase * delta), player_ref.global_position.x)
		camera.global_position.x = lerp(camera.global_position.x, x_alvo, 4.0 * delta)
		camera.global_position.y = lerp(camera.global_position.y, player_ref.global_position.y, 2.0 * delta)

func _executar_ataque() -> void:
	if not ativo or not is_instance_valid(player_ref):
		return

	var alvo = player_ref.global_position

	if mao_esquerda_vez:
		if is_instance_valid(mao_esq) and mao_esq.pode_atacar():
			mao_esq.atacar(alvo)
			mao_esquerda_vez = false
	else:
		if is_instance_valid(mao_dir) and mao_dir.pode_atacar():
			mao_dir.atacar(alvo)
			mao_esquerda_vez = true

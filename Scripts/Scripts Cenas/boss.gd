extends Node2D

@export var velocidade_chase: float = 120.0
var ativo: bool = false
var mao_esquerda_vez: bool = true
var player_ref: CharacterBody2D = null

@onready var camera: Camera2D = $CameraBoss
@onready var marker_esq: Marker2D = $MarkerMaoEsq
@onready var marker_dir: Marker2D = $MarkerMaoDir
@onready var mao_esq: Area2D = $MaoEsquerda
@onready var mao_dir: Area2D = $MaoDireita
@onready var timer_ataque: Timer = $TimerAtaque

func _ready() -> void:
	timer_ataque.timeout.connect(_executar_ataque)

func _process(delta: float) -> void:
	if not ativo:
		return

	# Deslocamento horizontal continuo da camera e do chefe
	position.x += velocidade_chase * delta

func iniciar_boss_fight(player: CharacterBody2D) -> void:
	player_ref = player
	camera.make_current()
	ativo = true
	timer_ataque.start()

func _executar_ataque() -> void:
	if not ativo or not is_instance_valid(player_ref):
		return

	var alvo = player_ref.global_position

	if mao_esquerda_vez:
		mao_esq.atacar(alvo, marker_esq)
	else:
		mao_dir.atacar(alvo, marker_dir)

	mao_esquerda_vez = not mao_esquerda_vez

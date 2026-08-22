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
	# Mantem o Boss totalmente desativado e invisivel no inicio do jogo
	hide()
	set_process(false)
	set_physics_process(false)

	if timer_ataque:
		timer_ataque.timeout.connect(_executar_ataque)

func iniciar_boss_fight(player: CharacterBody2D) -> void:
	player_ref = player
	ativo = true
	
	# Exibe o boss e ativa o processamento
	show()
	set_process(true)
	set_physics_process(true)

	# Posiciona a camera na posicao atual do jogador para evitar saltos bruscos
	if camera:
		camera.global_position = player.global_position
		camera.make_current()
	else:
		push_error("Erro: No 'CameraBoss' nao encontrado. Verifique o nome na cena!")

	if timer_ataque:
		timer_ataque.start()

func _process(delta: float) -> void:
	if not ativo:
		return

	# O Boss se move continuamente para a direita
	position.x += velocidade_chase * delta

	# Movimento dinamico da camera (Side-Scrolling enquadrando o jogador)
	if camera and is_instance_valid(player_ref):
		# A camera avanca na velocidade do Boss, mas desliza para frente se o jogador correr mais rapido
		var x_alvo = max(camera.global_position.x + (velocidade_chase * delta), player_ref.global_position.x)
		camera.global_position.x = lerp(camera.global_position.x, x_alvo, 4.0 * delta)
		camera.global_position.y = lerp(camera.global_position.y, player_ref.global_position.y, 2.0 * delta)

func _executar_ataque() -> void:
	if not ativo or not is_instance_valid(player_ref):
		return

	# Captura a posicao inicial/atual do jogador no momento que o Timer dispara
	var alvo = player_ref.global_position

	if mao_esquerda_vez:
		if is_instance_valid(mao_esq) and is_instance_valid(marker_esq):
			mao_esq.atacar(alvo, marker_esq)
	else:
		if is_instance_valid(mao_dir) and is_instance_valid(marker_dir):
			mao_dir.atacar(alvo, marker_dir)

	mao_esquerda_vez = not mao_esquerda_vez

extends Node2D

@export var velocidade_chase: float = 120.0
@export var margem_esquerda_pixels: float = 80.0 # Distancia do Boss até a borda esquerda da tela

var ativo: bool = false
var mao_esquerda_vez: bool = true
var player_ref: CharacterBody2D = null
var y_fixo_chao: float = 0.0 # Trava a altura do Boss para nao subir quando o jogador pular

@onready var camera: Camera2D = $CameraBoss
@onready var sprite_boss = $SpriteBoss
@onready var marker_esq: Marker2D = $MarkerMaoEsq
@onready var marker_dir: Marker2D = $MarkerMaoDir
@onready var mao_esq: Area2D = $MaoEsquerda
@onready var mao_dir: Area2D = $MaoDireita
@onready var timer_ataque: Timer = $TimerAtaque

func _ready() -> void:
	hide()
	modulate.a = 0.0
	set_process(false)
	set_physics_process(false)

	if is_instance_valid(mao_esq) and is_instance_valid(marker_esq):
		mao_esq.posicao_origem = marker_esq
		mao_esq.nome_animacao = "MaoEsquerda"

	if is_instance_valid(mao_dir) and is_instance_valid(marker_dir):
		mao_dir.posicao_origem = marker_dir
		mao_dir.nome_animacao = "MaoDireita"

	if timer_ataque:
		if timer_ataque.timeout.is_connected(_executar_ataque):
			timer_ataque.timeout.disconnect(_executar_ataque)
		timer_ataque.timeout.connect(_executar_ataque)

func iniciar_boss_fight(player: CharacterBody2D) -> void:
	player_ref = player
	ativo = true

	# Trava a altura Y no momento da ativacao para ignorar os pulos do jogador
	y_fixo_chao = player.global_position.y - 40.0
	
	# Calcula a metade da tela com base no zoom da camera
	var metade_largura_tela: float = 576.0 # Valor padrao de seguranca
	if camera:
		metade_largura_tela = (get_viewport_rect().size.x / camera.zoom.x) * 0.5
		# Posiciona a camera exatamente para deixar o Boss colado na borda esquerda
		camera.position = Vector2(metade_largura_tela - margem_esquerda_pixels, -30.0)
		camera.make_current()

	# Posiciona o Boss na altura fixa do chão e um pouco atrás do jogador
	global_position = Vector2(player.global_position.x - (metade_largura_tela * 1.2), y_fixo_chao)

	show()
	set_process(true)
	set_physics_process(true)

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.8)

	if sprite_boss is AnimatedSprite2D:
		sprite_boss.play()

	if is_instance_valid(mao_esq) and mao_esq.has_method("ativar_mao"):
		mao_esq.ativar_mao()
	if is_instance_valid(mao_dir) and mao_dir.has_method("ativar_mao"):
		mao_dir.ativar_mao()

	if timer_ataque:
		timer_ataque.start()

func _process(delta: float) -> void:
	if not ativo or not is_instance_valid(player_ref):
		return

	# Mantem a altura Y estritamente travada no chão (ignora pulo do player)
	global_position.y = y_fixo_chao

	# Deslocamento continuo para a direita
	global_position.x += velocidade_chase * delta

	# Se o jogador correr muito rápido para a frente, o Boss acelera para nao sumir
	var limite_distancia = camera.position.x * 1.6
	if player_ref.global_position.x > global_position.x + limite_distancia:
		global_position.x = lerp(global_position.x, player_ref.global_position.x - limite_distancia, 3.0 * delta)

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

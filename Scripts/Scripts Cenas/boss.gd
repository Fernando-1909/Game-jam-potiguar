extends Node2D

@export var velocidade_chase: float = 120.0
@export var margem_esquerda_pixels: float = 80.0 # Distancia do Boss ate a borda esquerda da tela
@export var tempo_introducao: float = 2.5 # Aumentado para 2.5s para uma transição bem suave

var ativo: bool = false
var perseguindo: bool = false # Controla quando o Boss realmente comeca a andar e atacar
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
	add_to_group("boss")
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

	if sprite_boss is AnimatedSprite2D:
		if not sprite_boss.animation_finished.is_connected(_on_sprite_boss_animation_finished):
			sprite_boss.animation_finished.connect(_on_sprite_boss_animation_finished)

func iniciar_boss_fight(player: CharacterBody2D) -> void:
	player_ref = player
	ativo = true
	perseguindo = false

	# Trava a altura Y no momento da ativacao
	y_fixo_chao = player.global_position.y - 40.0
	
	# Calcula a metade da tela com base no zoom final desejado (2.3)
	var metade_largura_tela: float = 576.0
	if camera:
		metade_largura_tela = (get_viewport_rect().size.x / 2.3) * 0.5

	# Posiciona o Boss na altura fixa do chão e um pouco atrás do jogador
	global_position = Vector2(player.global_position.x - (metade_largura_tela * 1.2), y_fixo_chao)

	# Posição local final onde a câmera deve parar em relação ao Boss
	var posicao_camera_alvo = Vector2(metade_largura_tela - margem_esquerda_pixels, -30.0)

	if camera:
		# Inicia no mesmo zoom do player (6.7)
		camera.zoom = Vector2(6.7, 6.7)
		
		# Inicia a camera do Boss EXATAMENTE na posição do Player para nao ter corte brusco
		camera.global_position = player.global_position
		camera.make_current()

	show()
	set_process(true)
	set_physics_process(true)

	if sprite_boss is AnimatedSprite2D:
		sprite_boss.play("Default")

	# --- TRANSICAO CINEMATICA (ZOOM + POSICAO + FADE IN) ---
	var tween = create_tween().set_parallel(true)
	
	# Aparecer o Boss gradualmente na tela
	tween.tween_property(self, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if camera:
		# Transição suave do Zoom de 6.7 para 2.3
		tween.tween_property(camera, "zoom", Vector2(2.3, 2.3), tempo_introducao)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			
		# Transição suave da Posição da câmera saindo do Player e indo para o enquadramento do Boss
		tween.tween_property(camera, "position", posicao_camera_alvo, tempo_introducao)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	# --- INÍCIO DA PERSEGUIÇÃO ---
	perseguindo = true

	if is_instance_valid(mao_esq) and mao_esq.has_method("ativar_mao"):
		mao_esq.ativar_mao()
	if is_instance_valid(mao_dir) and mao_dir.has_method("ativar_mao"):
		mao_dir.ativar_mao()

	if timer_ataque:
		timer_ataque.start()

func _process(delta: float) -> void:
	if not ativo or not is_instance_valid(player_ref):
		return

	global_position.y = y_fixo_chao

	if not perseguindo:
		return

	global_position.x += velocidade_chase * delta

	var limite_distancia = camera.position.x * 1.6
	if player_ref.global_position.x > global_position.x + limite_distancia:
		global_position.x = lerp(global_position.x, player_ref.global_position.x - limite_distancia, 3.0 * delta)

func _executar_ataque() -> void:
	if not ativo or not perseguindo or not is_instance_valid(player_ref):
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

func tocar_animacao_acerto() -> void:
	if sprite_boss and ativo and sprite_boss is AnimatedSprite2D:
		sprite_boss.play("Acerto")

func tomar_dano() -> void:
	if sprite_boss and ativo and sprite_boss is AnimatedSprite2D:
		sprite_boss.play("Acertado")

func _on_sprite_boss_animation_finished() -> void:
	if sprite_boss and ativo and sprite_boss is AnimatedSprite2D:
		if sprite_boss.animation != "Default":
			sprite_boss.play("Default")

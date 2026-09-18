extends Node2D

@export_group("Configurações do Boss")
@export var velocidade_chase: float = 120.0
@export var margem_esquerda_pixels: float = 80.0 # Distancia do Boss ate a borda esquerda da tela
@export var tempo_introducao: float = 2.5 # Tempo da transição inicial
@export var offset_altura_boss: float = -120.0 # Altura do Boss em relação ao chão (valores negativos sobem o Boss)

@export_group("Configurações da Câmera")
@export var zoom_final: Vector2 = Vector2(2.3, 2.3) # <--- Altere o Zoom aqui direto no Inspector
@export var margem_chao_bottom: float = 16.0 # <--- Ajuste de pixels para mostrar a espessura do piso sem mostrar o vazio

var ativo: bool = false
var perseguindo: bool = false
var mao_esquerda_vez: bool = true
var player_ref: CharacterBody2D = null
var y_fixo_chao: float = 0.0

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
	
	if sprite_boss.animation != "default":
		sprite_boss.play("default")

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

	# Define a posição vertical Y do Boss usando o offset do chão
	var y_chao_player = player.global_position.y
	y_fixo_chao = y_chao_player + offset_altura_boss

	# Calcula o tamanho da tela em pixels do mundo com base no zoom final
	var tamanho_viewport = get_viewport_rect().size
	var metade_largura_tela: float = (tamanho_viewport.x / zoom_final.x) * 0.5
	var metade_altura_tela: float = (tamanho_viewport.y / zoom_final.y) * 0.5

	# Posiciona o Boss na altura Y fixa
	global_position = Vector2(player.global_position.x - (metade_largura_tela * 1.2), y_fixo_chao)

	# CÁLCULO DINÂMICO DA CÂMERA:
	# Trava a borda inferior da câmera exatamente na altura do chão (+ margem do bloco)
	var y_camera_global_alvo = y_chao_player - metade_altura_tela + margem_chao_bottom
	var y_camera_local_alvo = y_camera_global_alvo - global_position.y

	var posicao_camera_alvo = Vector2(metade_largura_tela - margem_esquerda_pixels, y_camera_local_alvo)

	if camera:
		camera.zoom = Vector2(6.7, 6.7)
		camera.global_position = player.global_position
		camera.make_current()

	show()
	set_process(true)
	set_physics_process(true)

	if sprite_boss is AnimatedSprite2D:
		sprite_boss.play("Default")

	# --- TRANSIÇÃO CINEMÁTICA ---
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(self, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if camera:
		# Transição para o Zoom definido nas variáveis Export
		tween.tween_property(camera, "zoom", zoom_final, tempo_introducao)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			
		tween.tween_property(camera, "position", posicao_camera_alvo, tempo_introducao)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

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

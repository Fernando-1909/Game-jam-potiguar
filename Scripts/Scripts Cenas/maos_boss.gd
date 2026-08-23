extends Area2D

enum Estado { REPOUSO, ATACANDO, RETORNANDO }
var estado_atual: Estado = Estado.REPOUSO

var alvo_posicao: Vector2
var posicao_origem: Marker2D
var ativo: bool = false
var nome_animacao: String = ""

@onready var sprite_animado: AnimatedSprite2D = $SpriteMaos if has_node("SpriteMaos") else null

const VELOCIDADE_ATAQUE: float = 350.0
const VELOCIDADE_RETORNO: float = 150.0

func _ready() -> void:
	add_to_group("dano")
	body_entered.connect(_on_body_entered)
	monitoring = false
	monitorable = false
	top_level = true

func _process(delta: float) -> void:
	if not is_instance_valid(posicao_origem):
		return

	match estado_atual:
		Estado.REPOUSO:
			# Acompanha rigidamente o marcador no espaço global
			global_position = posicao_origem.global_position
			rotation = lerp_angle(rotation, 0.0, 10.0 * delta)

		Estado.ATACANDO:
			global_position = global_position.move_toward(alvo_posicao, VELOCIDADE_ATAQUE * delta)
			if global_position.distance_to(alvo_posicao) < 15.0:
				estado_atual = Estado.RETORNANDO

		Estado.RETORNANDO:
			var destino_atual = posicao_origem.global_position
			global_position = global_position.move_toward(destino_atual, VELOCIDADE_RETORNO * delta)
			rotation = lerp_angle(rotation, 0.0, 8.0 * delta)
			if global_position.distance_to(destino_atual) < 15.0:
				global_position = destino_atual
				rotation = 0.0
				estado_atual = Estado.REPOUSO

func ativar_mao() -> void:
	ativo = true
	monitoring = true
	monitorable = true

	if is_instance_valid(posicao_origem):
		global_position = posicao_origem.global_position

	if sprite_animado:
		if nome_animacao != "" and sprite_animado.sprite_frames and sprite_animado.sprite_frames.has_animation(nome_animacao):
			sprite_animado.play(nome_animacao)
		else:
			sprite_animado.play()

func pode_atacar() -> bool:
	return ativo and estado_atual == Estado.REPOUSO

func atacar(ponto_alvo: Vector2) -> void:
	if pode_atacar():
		look_at(ponto_alvo)
		var direcao = (ponto_alvo - global_position).normalized()
		alvo_posicao = ponto_alvo + (direcao * 80.0)
		estado_atual = Estado.ATACANDO

func _on_body_entered(body: Node2D) -> void:
	if not ativo:
		return

	if body.has_method("tomar_dano"):
		body.tomar_dano(33)

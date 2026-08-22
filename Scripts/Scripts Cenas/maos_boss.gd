extends Area2D

enum Estado { REPOUSO, ATACANDO, RETORNANDO }
var estado_atual: Estado = Estado.REPOUSO

var alvo_posicao: Vector2
var posicao_origem: Marker2D
const VELOCIDADE_ATAQUE: float = 500.0
const VELOCIDADE_RETORNO: float = 300.0

func _ready() -> void:
	# Adiciona o objeto ao grupo de dano automaticamente via codigo
	add_to_group("dano")

func _process(delta: float) -> void:
	match estado_atual:
		Estado.REPOUSO:
			if posicao_origem:
				global_position = global_position.lerp(posicao_origem.global_position, 10.0 * delta)
		Estado.ATACANDO:
			global_position = global_position.move_toward(alvo_posicao, VELOCIDADE_ATAQUE * delta)
			if global_position.distance_to(alvo_posicao) < 10.0:
				estado_atual = Estado.RETORNANDO
		Estado.RETORNANDO:
			if posicao_origem:
				global_position = global_position.move_toward(posicao_origem.global_position, VELOCIDADE_RETORNO * delta)
				if global_position.distance_to(posicao_origem.global_position) < 5.0:
					estado_atual = Estado.REPOUSO

func atacar(ponto_alvo: Vector2, marcador: Marker2D) -> void:
	if estado_atual == Estado.REPOUSO:
		alvo_posicao = ponto_alvo
		posicao_origem = marcador
		estado_atual = Estado.ATACANDO

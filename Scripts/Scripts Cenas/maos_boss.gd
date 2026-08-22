extends Area2D

enum Estado { REPOUSO, ATACANDO, RETORNANDO }
var estado_atual: Estado = Estado.REPOUSO

var alvo_posicao: Vector2
var posicao_origem: Marker2D
var ativo: bool = false

const VELOCIDADE_ATAQUE: float = 650.0
const VELOCIDADE_RETORNO: float = 450.0

func _ready() -> void:
	add_to_group("dano")
	body_entered.connect(_on_body_entered)
	# Desativa colisao e processamento no inicio para nao causar dano antecipado
	monitoring = false
	monitorable = false
	set_process(false)

func ativar_mao() -> void:
	ativo = true
	monitoring = true
	monitorable = true
	set_process(true)

func _process(delta: float) -> void:
	if not ativo or not is_instance_valid(posicao_origem):
		return

	match estado_atual:
		Estado.REPOUSO:
			# Trava a posicao diretamente no marcador em movimento continuo
			global_position = posicao_origem.global_position

		Estado.ATACANDO:
			global_position = global_position.move_toward(alvo_posicao, VELOCIDADE_ATAQUE * delta)
			if global_position.distance_to(alvo_posicao) < 15.0:
				estado_atual = Estado.RETORNANDO

		Estado.RETORNANDO:
			# Segue o marcador em movimento no mapa
			var destino_atual = posicao_origem.global_position
			global_position = global_position.move_toward(destino_atual, VELOCIDADE_RETORNO * delta)
			
			if global_position.distance_to(destino_atual) < 20.0:
				estado_atual = Estado.REPOUSO

func atacar(ponto_alvo: Vector2) -> void:
	if ativo and estado_atual == Estado.REPOUSO:
		alvo_posicao = ponto_alvo
		estado_atual = Estado.ATACANDO

func _on_body_entered(body: Node2D) -> void:
	if not ativo:
		return

	if body.has_method("tomar_dano"):
		body.tomar_dano(33)

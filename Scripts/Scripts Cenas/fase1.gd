extends Node2D

@onready var objetos_realidade: Node2D = $ObjetosRealidade
@onready var objetos_sonho: Node2D = $ObjetosSonho
@onready var ambiente: CanvasModulate = $Ambiente
@onready var game_over: CanvasLayer = $GameOver

var esta_sonhando: bool = false
var pode_alternar: bool = true

@export var tempo_espera_alternancia: float = 0.3

const COR_REALIDADE = Color(1.0, 1.0, 1.0)
const COR_SONHO = Color(0.735, 0.539, 0.118, 1.0)

func _ready():
	add_to_group("fase_atual")
	aplicar_estado(false)

func alternar_estado():
	if not pode_alternar:
		return

	var jogador = get_node_or_null("Player")
	
	# Verifica se a posicao atual no mundo oposto esta obstruida por blocos
	if jogador and jogador.has_method("esta_obstruido_na_camada"):
		# Se estamos na Realidade (!esta_sonhando), o destino e o Sonho (Layer 3 -> valor de mascara = 4)
		# Se estamos no Sonho (esta_sonhando), o destino e a Realidade (Layer 2 -> valor de mascara = 2)
		var mascara_destino = 4 if not esta_sonhando else 2
		
		if jogador.esta_obstruido_na_camada(mascara_destino):
			if jogador.has_method("exibir_aviso_obstrucao"):
				jogador.exibir_aviso_obstrucao("Dimensão Obstruída!")
			return

	esta_sonhando = !esta_sonhando
	pode_alternar = false

	aplicar_estado(true)

	await get_tree().create_timer(tempo_espera_alternancia).timeout
	pode_alternar = true

func aplicar_estado(animado: bool = true):
	# Alterna visibilidade visual
	if is_instance_valid(objetos_realidade):
		objetos_realidade.visible = !esta_sonhando
	if is_instance_valid(objetos_sonho):
		objetos_sonho.visible = esta_sonhando

	# Atualiza a mascara de colisao e fisica no script player.gd
	var jogador = get_node_or_null("Player")
	if jogador and jogador.has_method("atualizar_modo_sonho"):
		jogador.atualizar_modo_sonho(esta_sonhando)

	# Transicao da cor do ambiente
	var cor_alvo = COR_SONHO if esta_sonhando else COR_REALIDADE

	if animado:
		var tween = create_tween()
		tween.tween_property(ambiente, "color", cor_alvo, 0.3)
	else:
		ambiente.color = cor_alvo

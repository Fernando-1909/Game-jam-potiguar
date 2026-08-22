extends Node2D

@onready var objetos_realidade: Node2D = $ObjetosRealidade
@onready var objetos_sonho: Node2D = $ObjetosSonho
@onready var ambiente: CanvasModulate = $Ambiente
@onready var game_over: Control = $"."

var esta_sonhando: bool = false
var pode_alternar: bool = true

@export var tempo_espera_alternancia: float = 0.3

const COR_REALIDADE = Color(1.0, 1.0, 1.0)
const COR_SONHO = Color(0.735, 0.539, 0.118, 1.0)


func _ready():
	add_to_group("fase_atual")
	# Define o estado inicial da fase (comeca acordada, na realidade)
	aplicar_estado(false)


func alternar_estado():
	if not pode_alternar:
		return

	esta_sonhando = !esta_sonhando
	pode_alternar = false

	aplicar_estado(true)

	await get_tree().create_timer(tempo_espera_alternancia).timeout
	pode_alternar = true


func aplicar_estado(animado: bool = true):
	# Ativa ou desativa os containers de cada dimensao
	definir_container_ativo(objetos_realidade, !esta_sonhando)
	definir_container_ativo(objetos_sonho, esta_sonhando)

	# Atualiza a fisica no script player.gd
	var jogador = get_node_or_null("Player")
	if jogador and jogador.has_method("atualizar_modo_sonho"):
		jogador.atualizar_modo_sonho(esta_sonhando)

	# Transicao da cor do ambiente conforme o estado
	var cor_alvo = COR_SONHO if esta_sonhando else COR_REALIDADE

	if animado:
		var tween = create_tween()
		tween.tween_property(ambiente, "color", cor_alvo, 0.3)
	else:
		ambiente.color = cor_alvo


func definir_container_ativo(container: Node2D, ativo: bool):
	if not is_instance_valid(container):
		push_warning("Aviso: Um dos containers nao foi encontrado na arvore de cena.")
		return

	container.visible = ativo
	_alternar_colisoes_recursivo(container, ativo)


func _alternar_colisoes_recursivo(node: Node, ativo: bool):
	if node is CollisionShape2D or node is CollisionPolygon2D:
		node.set_deferred("disabled", !ativo)
	elif node is TileMapLayer:
		node.set_deferred("enabled", ativo)
	elif node is TileMap:
		for camada in node.get_layers_count():
			node.set_layer_enabled(camada, ativo)

	for filho in node.get_children():
		_alternar_colisoes_recursivo(filho, ativo)

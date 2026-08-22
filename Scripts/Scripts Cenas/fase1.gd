extends Node2D

@onready var objetos_realidade: Node2D = $ObjetosRealidade
@onready var objetos_sonho: Node2D = $ObjetosSonho
@onready var ambiente: CanvasModulate = $Ambiente

var esta_sonhando: bool = false
var pode_alternar: bool = true

@export var tempo_espera_alternancia: float = 0.3

const COR_REALIDADE = Color(1.0, 1.0, 1.0)
const COR_SONHO = Color(0.4, 0.2, 0.7)


func _ready():
	# Entra no grupo que o player usa para avisar "troca de estado agora"
	# (get_tree().call_group("fase_atual", "alternar_estado")).
	# Assim qualquer fase nova que entrar nesse grupo já funciona sem mexer no player.
	add_to_group("fase_atual")

	# Define o estado inicial da fase (começa acordada, na realidade)
	aplicar_estado(false)

	# Posição inicial do Player
	#player.position = Vector2(100, 100)


func alternar_estado():
	if not pode_alternar:
		return

	esta_sonhando = !esta_sonhando
	pode_alternar = false

	aplicar_estado(true)

	await get_tree().create_timer(tempo_espera_alternancia).timeout
	pode_alternar = true


func aplicar_estado(animado: bool = true):
	# Ativa os objetos do estado "acordada" (realidade) e desativa se estiver sonhando
	definir_container_ativo(objetos_realidade, !esta_sonhando)

	# Ativa os objetos do estado "sonhando" e desativa se estiver acordada
	definir_container_ativo(objetos_sonho, esta_sonhando)

	# Transição da cor do ambiente conforme o estado
	var cor_alvo = COR_SONHO if esta_sonhando else COR_REALIDADE

	if animado:
		var tween = create_tween()
		tween.tween_property(ambiente, "color", cor_alvo, 0.3)
	else:
		ambiente.color = cor_alvo


func definir_container_ativo(container: Node2D, ativo: bool):
	if not is_instance_valid(container):
		push_warning("Aviso: Um dos containers não foi encontrado na árvore de cena.")
		return

	container.visible = ativo
	_alternar_colisoes_recursivo(container, ativo)


func _alternar_colisoes_recursivo(node: Node, ativo: bool):
	if node is CollisionShape2D or node is CollisionPolygon2D:
		node.set_deferred("disabled", !ativo)

	for filho in node.get_children():
		_alternar_colisoes_recursivo(filho, ativo)

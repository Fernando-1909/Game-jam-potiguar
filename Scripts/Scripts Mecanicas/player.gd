extends CharacterBody2D

# Parametros de fisica - Mundo Real (Acordada)
const VELOCIDADE_REAL: float = 350.0
const PULO_REAL: float = -700.0
const MULTIPLICADOR_GRAVIDADE_REAL: float = 1.0

# Parametros de fisica - Ecdise (Mundo dos Sonhos)
const VELOCIDADE_SONHO: float = 180.0
const PULO_SONHO: float = -950.0
const MULTIPLICADOR_GRAVIDADE_SONHO: float = 0.55

# Parametros do Sistema de Insonia (Vida)
@export var insonia_maxima: float = 3.0
var insonia_atual: float = 3.0

const TAXA_DRENAGEM_REAL: float = 0.05       # Perda contínua de vida no mundo real
const TAXA_RECUPERACAO_SONHO: float = 0.15   # Recuperação contínua no mundo dos sonhos

var esta_sonhando_player: bool = false
var esta_invencivel: bool = false

# Referencias de nos filhos
@onready var barra_vida: ProgressBar = $UI/BarraVida

# Variaveis ativas de controle de fisica
var velocidade_atual: float = VELOCIDADE_REAL
var pulo_atual: float = PULO_REAL
var multiplicador_gravidade_atual: float = MULTIPLICADOR_GRAVIDADE_REAL
var gravidade_base: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	insonia_atual = insonia_maxima
	if barra_vida:
		barra_vida.max_value = insonia_maxima
		barra_vida.value = insonia_atual

func _physics_process(delta: float) -> void:
	_processar_insonia(delta)

	if not is_on_floor():
		var gravidade_calculada = gravidade_base * multiplicador_gravidade_atual
		velocity.y += gravidade_calculada * delta

	if Input.is_action_just_pressed("Pulo") and is_on_floor():
		velocity.y = pulo_atual

	var direcao = Input.get_axis("Esquerda", "Direita")
	if direcao:
		velocity.x = direcao * velocidade_atual
	else:
		velocity.x = move_toward(velocity.x, 0, velocidade_atual)

	move_and_slide()

# Gerencia o ganho e a perda continua de insonia
func _processar_insonia(delta: float) -> void:
	if esta_sonhando_player:
		insonia_atual = move_toward(insonia_atual, insonia_maxima, TAXA_RECUPERACAO_SONHO * delta)
	else:
		insonia_atual = move_toward(insonia_atual, 0.0, TAXA_DRENAGEM_REAL * delta)
		if insonia_atual <= 0.0:
			morrer()

	if barra_vida:
		barra_vida.value = insonia_atual

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Mudar estado") and not event.is_echo():
		get_tree().call_group("fase_atual", "alternar_estado")

# Metodo chamado pelo script da fase ao realizar a troca de mundo
func atualizar_modo_sonho(esta_sonhando: bool) -> void:
	esta_sonhando_player = esta_sonhando
	if esta_sonhando:
		velocidade_atual = VELOCIDADE_SONHO
		pulo_atual = PULO_SONHO
		multiplicador_gravidade_atual = MULTIPLICADOR_GRAVIDADE_SONHO
	else:
		velocidade_atual = VELOCIDADE_REAL
		pulo_atual = PULO_REAL
		multiplicador_gravidade_atual = MULTIPLICADOR_GRAVIDADE_REAL

# Aplica dano inteiro ao ser atingida por obstaculos ou inimigos
func tomar_dano(quantidade: float = 1.0) -> void:
	if esta_invencivel:
		return

	insonia_atual -= quantidade
	esta_invencivel = true

	# Se for atingida no mundo dos sonhos, e forcada a voltar ao mundo real
	if esta_sonhando_player:
		get_tree().call_group("fase_atual", "alternar_estado")

	if insonia_atual <= 0.0:
		morrer()
	else:
		# Periodo de invencibilidade temporario contra danos seguidos
		await get_tree().create_timer(1.0).timeout
		esta_invencivel = false

func morrer() -> void:
	# Reinicia a fase ao zerar os pontos de insonia
	get_tree().reload_current_scene()

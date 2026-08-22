extends CharacterBody2D

# Parametros de fisica - Mundo Real (Acordada)
const VELOCIDADE_REAL: float = 350.0
const PULO_REAL: float = -700.0
const MULTIPLICADOR_GRAVIDADE_REAL: float = 1.0

# Parametros de fisica - Ecdise (Mundo dos Sonhos)
const VELOCIDADE_SONHO: float = 180.0
const PULO_SONHO: float = -950.0
const MULTIPLICADOR_GRAVIDADE_SONHO: float = 0.55

# Parametros do Sistema de Insonia (0 a 100)
@export var insonia_maxima: int = 100
var insonia_atual: int = 0

var acumulador_tempo_insonia: float = 0.0
var esta_sonhando_player: bool = false
var esta_invencivel: bool = false

# Cores para o preenchimento da barra
const COR_AZUL_BEBE = Color("87CEEB")
const COR_LILAS = Color("C77DFF")
const COR_VERMELHO = Color("FF4D6D")

# Referencias de nos
@onready var barra_vida: ProgressBar = $UI/BarraVida

# Variaveis ativas de controle de fisica
var velocidade_atual: float = VELOCIDADE_REAL
var pulo_atual: float = PULO_REAL
var multiplicador_gravidade_atual: float = MULTIPLICADOR_GRAVIDADE_REAL
var gravidade_base: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	insonia_atual = 0
	if barra_vida:
		barra_vida.min_value = 0
		barra_vida.max_value = insonia_maxima
		_atualizar_interface_ui()

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

# Incrementa ou decrementa a insonia em intervalos fixos de 0.5 segundos
func _processar_insonia(delta: float) -> void:
	acumulador_tempo_insonia += delta

	if acumulador_tempo_insonia >= 0.5:
		acumulador_tempo_insonia -= 0.5

		if esta_sonhando_player:
			# Na Ecdise, reduz 3 pontos de insonia
			insonia_atual = clampi(insonia_atual - 3, 0, insonia_maxima)
		else:
			# No mundo real, aumenta 1 ponto de insonia
			insonia_atual = clampi(insonia_atual + 1, 0, insonia_maxima)
			if insonia_atual >= insonia_maxima:
				morrer()

		_atualizar_interface_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Mudar estado") and not event.is_echo():
		get_tree().call_group("fase_atual", "alternar_estado")

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

# Recebe dano inteiro e preenche a barra de insonia
func tomar_dano(quantidade: int = 25) -> void:
	if esta_invencivel:
		return

	insonia_atual = clampi(insonia_atual + quantidade, 0, insonia_maxima)
	esta_invencivel = true
	_atualizar_interface_ui()

	# Se for atingida no mundo dos sonhos, retorna ao mundo real
	if esta_sonhando_player:
		get_tree().call_group("fase_atual", "alternar_estado")

	if insonia_atual >= insonia_maxima:
		morrer()
	else:
		await get_tree().create_timer(1.0).timeout
		esta_invencivel = false

# Atualiza a interface e faz a transicao visual de cores da barra
func _atualizar_interface_ui() -> void:
	if not barra_vida:
		return

	barra_vida.value = insonia_atual

	var stylebox = StyleBoxFlat.new()

	if insonia_atual < 40:
		stylebox.bg_color = COR_AZUL_BEBE
	elif insonia_atual < 75:
		stylebox.bg_color = COR_LILAS
	else:
		stylebox.bg_color = COR_VERMELHO

	barra_vida.add_theme_stylebox_override("fill", stylebox)

func morrer() -> void:
	get_tree().reload_current_scene()

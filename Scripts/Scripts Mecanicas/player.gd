extends CharacterBody2D

# Parametros de fisica - Mundo Real (Acordada)
const VELOCIDADE_REAL: float = 350.0
const PULO_REAL: float = -700.0
const MULTIPLICADOR_GRAVIDADE_REAL: float = 1.0

# Parametros de fisica - Ecdise (Mundo dos Sonhos)
const VELOCIDADE_SONHO: float = 180.0
const PULO_SONHO: float = -950.0
const MULTIPLICADOR_GRAVIDADE_SONHO: float = 0.55 # Valor menor gera uma queda leve e flutuante

# Variaveis ativas de controle
var velocidade_atual: float = VELOCIDADE_REAL
var pulo_atual: float = PULO_REAL
var multiplicador_gravidade_atual: float = MULTIPLICADOR_GRAVIDADE_REAL

# Gravidade padrao das configuracoes do projeto Godot
var gravidade_base: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	# Aplica a gravidade ajustada caso nao esteja no chao
	if not is_on_floor():
		var gravidade_calculada = gravidade_base * multiplicador_gravidade_atual
		velocity.y += gravidade_calculada * delta

	# Executa o pulo com a forca da dimensao ativa
	if Input.is_action_just_pressed("Pulo") and is_on_floor():
		velocity.y = pulo_atual

	# Movimento horizontal (correr no mundo real / andar devagar na ecdise)
	var direcao = Input.get_axis("Esquerda", "Direita")
	if direcao:
		velocity.x = direcao * velocidade_atual
	else:
		velocity.x = move_toward(velocity.x, 0, velocidade_atual)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Mudar estado") and not event.is_echo():
		get_tree().call_group("fase_atual", "alternar_estado")

# Metodo chamado pelo script da fase ao realizar a troca de mundo
func atualizar_modo_sonho(esta_sonhando: bool) -> void:
	if esta_sonhando:
		velocidade_atual = VELOCIDADE_SONHO
		pulo_atual = PULO_SONHO
		multiplicador_gravidade_atual = MULTIPLICADOR_GRAVIDADE_SONHO
	else:
		velocidade_atual = VELOCIDADE_REAL
		pulo_atual = PULO_REAL
		multiplicador_gravidade_atual = MULTIPLICADOR_GRAVIDADE_REAL

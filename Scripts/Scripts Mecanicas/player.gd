extends CharacterBody2D

# Parametros de fisica - Mundo Real (Acordada)
const VELOCIDADE_REAL: float = 165.0
const PULO_REAL: float = -590.0
const MULTIPLICADOR_GRAVIDADE_REAL: float = 1.0

# Parametros de fisica - Ecdise (Mundo dos Sonhos)
const VELOCIDADE_SONHO: float = 100.0
const PULO_SONHO: float = -590.0
const MULTIPLICADOR_GRAVIDADE_SONHO: float = 0.55

# Parametros de Knockback
const FORCA_KNOCKBACK_X: float = 250.0
const FORCA_KNOCKBACK_Y: float = -300.0

@onready var SpriteProtagonista = $SpriteProtagonista

# Parametros do Sistema de Insonia (0 a 100)
@export var insonia_maxima: int = 100
var insonia_atual: int = 0

var acumulador_tempo_insonia: float = 0.0
var esta_sonhando_player: bool = false
var esta_invencivel: bool = false
var esta_em_knockback: bool = false
var esta_morto: bool = false

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
	if esta_morto:
		return

	_processar_insonia(delta)

	if not is_on_floor():
		var gravidade_calculada = gravidade_base * multiplicador_gravidade_atual
		velocity.y += gravidade_calculada * delta

	# Enquanto estiver sofrendo o impulse de knockback, o input do jogador fica bloqueado
	if not esta_em_knockback:
		if Input.is_action_just_pressed("Pulo") and is_on_floor():
			velocity.y = pulo_atual

		var direcao = Input.get_axis("Esquerda", "Direita")
		if direcao:
			velocity.x = direcao * velocidade_atual
		else:
			velocity.x = move_toward(velocity.x, 0, velocidade_atual)

		if direcao == 1.0:
			SpriteProtagonista.flip_h = false
		elif direcao == -1.0:
			SpriteProtagonista.flip_h = true

	move_and_slide()
	_verificar_colisoes_dano()

func _verificar_colisoes_dano() -> void:
	if esta_invencivel or esta_morto:
		return

	for i in get_slide_collision_count():
		var colisao = get_slide_collision(i)
		var colisor = colisao.get_collider()

		if not is_instance_valid(colisor):
			continue

		var causou_dano: bool = false

		# Detecta colisao em TileMapLayer ou TileMap tradicional
		if colisor is TileMapLayer or colisor is TileMap:
			var tile_set: TileSet = colisor.tile_set
			if tile_set and tile_set.has_custom_data_layer_by_name("causa_dano"):
				var ponto_impacto = colisao.get_position() - (colisao.get_normal() * 4.0)
				var ponto_local = colisor.to_local(ponto_impacto)
				var coords = colisor.local_to_map(ponto_local)

				var tile_data: TileData = null
				if colisor is TileMapLayer:
					tile_data = colisor.get_cell_tile_data(coords)
				elif colisor is TileMap:
					for camada in colisor.get_layers_count():
						var data_temp = colisor.get_cell_tile_data(camada, coords)
						if data_temp:
							tile_data = data_temp
							break

				if tile_data and tile_data.get_custom_data("causa_dano") == true:
					causou_dano = true

		# Detecta colisao em objetos soltos ou inimigos
		elif colisor.is_in_group("dano") or colisor.get("causa_dano") == true:
			causou_dano = true

		if causou_dano:
			tomar_dano(33)
			break

# Incrementa ou decrementa a insonia em intervalos fixos de 0.5 segundos
func _processar_insonia(delta: float) -> void:
	if esta_morto:
		return

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
	if esta_morto:
		return

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

# Recebe dano inteiro, aplica knockback e preenche a barra de insonia
func tomar_dano(quantidade: int = 33) -> void:
	if esta_invencivel or esta_morto:
		return

	insonia_atual = clampi(insonia_atual + quantidade, 0, insonia_maxima)
	esta_invencivel = true
	_atualizar_interface_ui()

	# Aplica knockback no sentido oposto ao que o sprite esta olhando
	var direcao_knockback: float = 1.0 if SpriteProtagonista.flip_h else -1.0
	velocity.x = direcao_knockback * FORCA_KNOCKBACK_X
	velocity.y = FORCA_KNOCKBACK_Y
	esta_em_knockback = true
	_encerrar_knockback_apos_tempo(0.2)

	# Se for atingida no mundo dos sonhos, retorna ao mundo real
	if esta_sonhando_player:
		get_tree().call_group("fase_atual", "alternar_estado")

	if insonia_atual >= insonia_maxima:
		morrer()
	else:
		# Efeito visual de piscar durante o tempo de invencibilidade (1.5s)
		var tween = create_tween().set_loops(7)
		tween.tween_property(self, "modulate:a", 0.2, 0.1)
		tween.tween_property(self, "modulate:a", 1.0, 0.1)

		await get_tree().create_timer(1.5).timeout

		if not esta_morto:
			esta_invencivel = false
			modulate.a = 1.0

func _encerrar_knockback_apos_tempo(tempo: float) -> void:
	await get_tree().create_timer(tempo).timeout
	esta_em_knockback = false

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
	if esta_morto:
		return

	esta_morto = true
	set_physics_process(false)

	if is_inside_tree() and get_tree():
		get_tree().reload_current_scene()

func _input(event):
	if (event.is_action_pressed("Descer")):
		print("desceu")
		position.y += 5

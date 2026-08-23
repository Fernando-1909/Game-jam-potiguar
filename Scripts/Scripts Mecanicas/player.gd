extends CharacterBody2D

@onready var SpriteProtagonista = $SpriteProtagonista
@onready var camera: Camera2D = $Camera2D
@onready var sfx_pulo: AudioStreamPlayer = $Sfx_pulo

# Parametros de fisica - Mundo Real (Acordada)
const VELOCIDADE_REAL: float = 135.0
const PULO_REAL: float = -460.0
const MULTIPLICADOR_GRAVIDADE_REAL: float = 0.63

# Parametros de fisica - Ecdise (Mundo dos Sonhos)
const VELOCIDADE_SONHO: float = 76.0
const PULO_SONHO: float = -395.0
const MULTIPLICADOR_GRAVIDADE_SONHO: float = 0.40

# Parametros do Sistema de Insonia (0 a 100)
@export var insonia_maxima: int = 100
@export var ganho_insonia_real: float = 1.3
@export var cura_insonia_sonho: float = 0.7 

var insonia_atual: int = 0
var acumulador_tempo_insonia: float = 0.0
var esta_sonhando_player: bool = false
var esta_invencivel: bool = false
var esta_em_knockback: bool = false

# Cores para o preenchimento da barra
const COR_AZUL_BEBE = Color("87CEEB")
const COR_LILAS = Color("C77DFF")
const COR_VERMELHO = Color("FF4D6D")

# Referencias de nos da UI e Colisao
@onready var barra_vida: ProgressBar = $UI/BarraVida
@onready var container_aviso: PanelContainer = $UI/ContainerAviso
@onready var label_aviso: Label = $UI/ContainerAviso/MarginContainer/LabelAviso
@onready var colisor_player: CollisionShape2D = $CollisionShape2D

# Variaveis ativas de controle de fisica
var velocidade_atual: float = VELOCIDADE_REAL
var pulo_atual: float = PULO_REAL
var multiplicador_gravidade_atual: float = MULTIPLICADOR_GRAVIDADE_REAL
var gravidade_base: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var tween_aviso: Tween

func _ready() -> void:
	insonia_atual = 0
	if barra_vida:
		barra_vida.min_value = 0
		barra_vida.max_value = insonia_maxima
		_atualizar_interface_ui()

	if camera:
		camera.reset_smoothing()

	# Configura a mascara inicial (Layer 1 Geral + Layer 2 Realidade)
	collision_mask = 1 + 2

func _physics_process(delta: float) -> void:
	_processar_insonia(delta)

	if not esta_em_knockback:
		if Input.is_action_just_pressed("Descer") and is_on_floor():
			_descer_plataforma()
		elif Input.is_action_just_pressed("Pulo") and is_on_floor():
			sfx_pulo.play()
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

	if not is_on_floor():
		var gravidade_calculada = gravidade_base * multiplicador_gravidade_atual
		velocity.y += gravidade_calculada * delta

		if velocity.y > 0:
			if SpriteProtagonista.animation != "Falling":
				SpriteProtagonista.play("Falling")
		elif velocity.y < 0:
			if SpriteProtagonista.animation != "Jump":
				SpriteProtagonista.play("Jump")
	else:
		if abs(velocity.x) > 1:
			if SpriteProtagonista.animation != "Walk":
				SpriteProtagonista.play("Walk")
		else:
			if SpriteProtagonista.animation != "Idle":
				SpriteProtagonista.play("Idle")

	move_and_slide()
	_verificar_colisoes_dano()

func esta_obstruido_na_camada(mascara_camada: int) -> bool:
	if not colisor_player or not colisor_player.shape:
		return false

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = colisor_player.shape
	query.transform = global_transform
	query.collision_mask = mascara_camada
	query.exclude = [get_rid()]

	var espaco_fisica = get_world_2d().direct_space_state
	var colisoes = espaco_fisica.intersect_shape(query, 1)

	return colisoes.size() > 0

func exibir_aviso_obstrucao(texto: String = "Caminho bloqueado na outra dimensão!") -> void:
	if not container_aviso:
		return

	if label_aviso:
		label_aviso.text = texto

	container_aviso.visible = true
	container_aviso.modulate.a = 1.0

	if tween_aviso and tween_aviso.is_running():
		tween_aviso.kill()

	tween_aviso = create_tween()
	tween_aviso.tween_interval(2.0)
	tween_aviso.tween_property(container_aviso, "modulate:a", 0.0, 0.4)
	
	await tween_aviso.finished
	
	if container_aviso.modulate.a == 0.0:
		container_aviso.visible = false

func _verificar_colisoes_dano() -> void:
	if esta_invencivel:
		return

	for i in get_slide_collision_count():
		var colisao = get_slide_collision(i)
		var colisor = colisao.get_collider()

		if not is_instance_valid(colisor):
			continue

		var causou_dano: bool = false

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

		elif colisor.is_in_group("dano") or colisor.get("causa_dano") == true:
			causou_dano = true

		if causou_dano:
			tomar_dano(33)
			break

func _processar_insonia(delta: float) -> void:
	acumulador_tempo_insonia += delta

	if acumulador_tempo_insonia >= 0.5:
		acumulador_tempo_insonia -= 0.5

		if esta_sonhando_player:
			insonia_atual = clampi(insonia_atual - cura_insonia_sonho, 0, insonia_maxima)
		else:
			insonia_atual = clampi(insonia_atual + ganho_insonia_real, 0, insonia_maxima)
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
		# Layer 1 (chao geral) + Layer 3 (Mundo dos Sonhos = bit 4)
		collision_mask = 1 + 4
	else:
		velocidade_atual = VELOCIDADE_REAL
		pulo_atual = PULO_REAL
		multiplicador_gravidade_atual = MULTIPLICADOR_GRAVIDADE_REAL
		# Layer 1 (chao geral) + Layer 2 (Mundo Real = bit 2)
		collision_mask = 1 + 2

func tomar_dano(quantidade: int = 33) -> void:
	if esta_invencivel:
		return

	get_tree().call_group("boss", "tocar_animacao_acerto")

	insonia_atual = clampi(insonia_atual + quantidade, 0, insonia_maxima)
	esta_invencivel = true
	_atualizar_interface_ui()

	if insonia_atual >= insonia_maxima:
		morrer()
		return

	var direcao_knockback: float = 1.0 if SpriteProtagonista.flip_h else -1.0
	velocity.x = direcao_knockback * 250.0
	velocity.y = -300.0
	esta_em_knockback = true
	_encerrar_knockback_apos_tempo(0.2)

	if esta_sonhando_player:
		get_tree().call_group("fase_atual", "alternar_estado")

	var tween = create_tween().set_loops(7)
	tween.tween_property(self, "modulate:a", 0.2, 0.1)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)

	await get_tree().create_timer(1.5).timeout
	esta_invencivel = false
	modulate.a = 1.0

func _encerrar_knockback_apos_tempo(tempo: float) -> void:
	await get_tree().create_timer(tempo).timeout
	esta_em_knockback = false

func _atualizar_interface_ui() -> void:
	if not barra_vida:
		return

	barra_vida.value = insonia_atual

	var porcentagem: float = float(insonia_atual) / float(insonia_maxima)

	if porcentagem < 0.25:
		$UI/BarraVida/BarraHP.play("hp1")
	elif porcentagem < 0.50:
		$UI/BarraVida/BarraHP.play("hp2")
	elif porcentagem < 0.75:
		$UI/BarraVida/BarraHP.play("hp3")
	else:
		$UI/BarraVida/BarraHP.play("hp4")



	barra_vida.value = insonia_atual

	var stylebox = StyleBoxFlat.new()
	stylebox.set_corner_radius_all(4)
	stylebox.content_margin_left = 2.0
	stylebox.content_margin_top = 2.0
	stylebox.content_margin_right = 2.0
	stylebox.content_margin_bottom = 2.0

	if insonia_atual < 40:
		stylebox.bg_color = COR_AZUL_BEBE
	elif insonia_atual < 75:
		stylebox.bg_color = COR_LILAS
	else:
		stylebox.bg_color = COR_VERMELHO

	barra_vida.add_theme_stylebox_override("fill", stylebox)

func _descer_plataforma() -> void:
	if not is_on_floor():
		return

	global_position.y += 8.0
	velocity.y = 50.0

func morrer() -> void:
	insonia_atual = insonia_maxima
	_atualizar_interface_ui()
	set_physics_process(false)

	var no_game_over = get_tree().get_first_node_in_group("game_over")
	if no_game_over and no_game_over.has_method("game_over"):
		no_game_over.game_over()
	elif has_node("../GameOver"):
		get_node("../GameOver").game_over()
	elif has_node("UI/GameOver"):
		get_node("UI/GameOver").game_over()

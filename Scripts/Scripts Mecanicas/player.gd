extends CharacterBody2D

const VELOCIDADE = 300.0
const VELOCIDADE_PULO = -400.0
var gravidade = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravidade * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = VELOCIDADE_PULO

	var direcao = Input.get_axis("ui_left", "ui_right")
	if direcao:
		velocity.x = direcao * VELOCIDADE
	else:
		velocity.x = move_toward(velocity.x, 0, VELOCIDADE)

	move_and_slide()

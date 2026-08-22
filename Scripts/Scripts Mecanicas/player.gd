extends CharacterBody2D

const VELOCIDADE = 350.0
const VELOCIDADE_PULO = -850.0

var gravidade = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravidade * delta

	if Input.is_action_just_pressed("Pulo") and is_on_floor():
		velocity.y = VELOCIDADE_PULO

	var direcao = Input.get_axis("Esquerda", "Direita")
	if direcao:
		velocity.x = direcao * VELOCIDADE
	else:
		velocity.x = move_toward(velocity.x, 0, VELOCIDADE)

	move_and_slide()


func _unhandled_input(event):
	if event.is_action_pressed("Mudar estado") and not event.is_echo():
		get_tree().call_group("fase_atual", "alternar_estado")

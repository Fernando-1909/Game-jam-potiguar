extends CharacterBody2D

const VELOCIDADE = 350.0
const VELOCIDADE_PULO = -850.0

# Tecla usada para alternar entre os estados "acordada" e "sonhando".
# Fica aqui no player porque essa mudança acontece em todas as fases.
const TECLA_ALTERNAR_ESTADO = KEY_Z

var gravidade = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravidade * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = VELOCIDADE_PULO

	var direcao = Input.get_axis("Esquerda", "Direita")
	if direcao:
		velocity.x = direcao * VELOCIDADE
	else:
		velocity.x = move_toward(velocity.x, 0, VELOCIDADE)

	move_and_slide()


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == TECLA_ALTERNAR_ESTADO:
			get_tree().call_group("fase_atual", "alternar_estado")

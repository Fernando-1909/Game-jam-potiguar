extends Node2D

@onready var real_objects: Node2D = $RealObjects
@onready var dream_objects: Node2D = $DreamObjects
@onready var atmosphere: CanvasModulate = $Atmosphere

var is_dream_world: bool = false
var can_toggle: bool = true

# Tempo de espera entre uma troca e outra (evita bugs de física ao spamar a tecla)
@export var toggle_cooldown: float = 0.3

# Cores de cada dimensão
const COLOR_REAL = Color(1.0, 1.0, 1.0)        # Cor normal
const COLOR_DREAM = Color(0.4, 0.2, 0.7)       # Cor arroxeada/mística

func _ready():
	# Define o estado inicial da fase (Mundo Real ativado)
	apply_dimension_state(false)

func _unhandled_input(event):
	if Input.is_action_just_pressed("trocar_dimensao") and can_toggle:
		toggle_dimension()

func toggle_dimension():
	is_dream_world = !is_dream_world
	can_toggle = false
	
	apply_dimension_state(true)
	
	# Aguarda o tempo de cooldown para permitir uma nova troca
	await get_tree().create_timer(toggle_cooldown).timeout
	can_toggle = true

func apply_dimension_state(animated: bool = true):
	# 1. Ativa/Desativa o Mundo Real
	set_container_active(real_objects, !is_dream_world)
	
	# 2. Ativa/Desativa o Mundo dos Sonhos
	set_container_active(dream_objects, is_dream_world)
	
	# 3. Transição de cor suave do ambiente usando Tween
	var target_color = COLOR_DREAM if is_dream_world else COLOR_REAL
	if animated:
		var tween = create_tween()
		tween.tween_property(atmosphere, "color", target_color, 0.3)
	else:
		atmosphere.color = target_color

# Desativa visibilidade e colisão de todos os elementos dentro do nó filho
func set_container_active(container: Node2D, active: bool):
	container.visible = active
	_toggle_collisions_recursive(container, active)

func _toggle_collisions_recursive(node: Node, active: bool):
	if node is CollisionShape2D or node is CollisionPolygon2D:
		node.set_deferred("disabled", !active)
	
	for child in node.get_children():
		_toggle_collisions_recursive(child, active)

extends CanvasLayer

@export_file("*.tscn") var cena_creditos: String = "res://creditos.tscn"
@export var tempo_por_letra: float = 0.05  # Velocidade do efeito de digitação
@export var tempo_leitura: float = 2.0      # Tempo que a frase fica legível antes da próxima

@onready var label_texto: Label = $Label

var falas: Array[String] = [
	"- será que a mamãe já tá dormindo?",
	"- tá tarde...",
	"- ...",
	"- Melhor voltar pro meu quarto.",
	"- Não tenho medo de fantasmas."
]

func _ready() -> void:
	label_texto.text = ""
	_iniciar_encerramento()

func _iniciar_encerramento() -> void:
	for fala in falas:
		label_texto.text = fala
		label_texto.visible_ratio = 0.0
		
		# Anima o texto surgindo letra por letra
		var tempo_total_digitar = fala.length() * tempo_por_letra
		var tween = create_tween()
		tween.tween_property(label_texto, "visible_ratio", 1.0, tempo_total_digitar)
		await tween.finished
		
		# Aguarda o jogador ler a frase completa
		await get_tree().create_timer(tempo_leitura).timeout
	
	# Transiciona diretamente para a tela de créditos
	if cena_creditos != "":
		get_tree().change_scene_to_file(cena_creditos)

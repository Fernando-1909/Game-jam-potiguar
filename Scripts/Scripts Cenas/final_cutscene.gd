class_name CutsceneTexto
extends CanvasLayer

# Variável estática que persiste entre a troca de cenas
static var modo_introducao: bool = true 

@export_file("*.tscn") var cena_fase1: String = "res://Cenas do jogo/Fase1.tscn"
@export_file("*.tscn") var cena_creditos: String = "res://creditos.tscn"

@export var tempo_por_letra: float = 0.05  # Velocidade do efeito de digitação
@export var tempo_leitura: float = 2.0      # Tempo de pausa após a frase terminar

@onready var label_texto: Label = $Label

# Sequência de falas da Introdução (Início do jogo)
var falas_intro: Array[String] = [
	"- Está tudo tão escuro...",
	"- Sinto que preciso ter cuidado ao caminhar.",
	"- Preciso atravessar isso logo."
]

# Sequência de falas do Final (Encerramento do jogo)
var falas_final: Array[String] = [
	"- será que a mamãe já tá dormindo?",
	"- tá tarde...",
	"- ...",
	"- Melhor voltar pro meu quarto.",
	"- Não tenho medo de fantasmas."
]

func _ready() -> void:
	if label_texto:
		label_texto.text = ""
	_executar_cutscene()

func _executar_cutscene() -> void:
	# Seleciona o grupo de falas e o destino correto com base no modo
	var falas_atuais = falas_intro if modo_introducao else falas_final
	var cena_destino = cena_fase1 if modo_introducao else cena_creditos

	for fala in falas_atuais:
		label_texto.text = fala
		label_texto.visible_ratio = 0.0
		
		# Anima o texto surgindo letra por letra
		var tempo_total_digitar = fala.length() * tempo_por_letra
		var tween = create_tween()
		tween.tween_property(label_texto, "visible_ratio", 1.0, tempo_total_digitar)
		await tween.finished
		
		# Aguarda o tempo de leitura da frase completa
		await get_tree().create_timer(tempo_leitura).timeout
	
	# Troca para a cena correspondente
	if cena_destino != "":
		get_tree().change_scene_to_file(cena_destino)

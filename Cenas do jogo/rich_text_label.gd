
extends RichTextLabel

var tempo := 0.0

func _ready():
	bbcode_enabled = true
	text = "[center][wave][rainbow]Caminho secreto![/rainbow][/wave][/center]"

func _process(delta):
	tempo += delta

	# Anima a onda
	var velocidade := 3.0
	var amplitude := 5.0

	# O efeito [wave] do RichTextLabel já é animado pelo Godot.
	# Atualizamos o texto para manter a animação funcionando.
	if tempo > 0.05:
		visible_characters = -1

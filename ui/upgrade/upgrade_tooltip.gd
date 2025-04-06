extends Control
@onready var textbox = $Panel/MarginContainer/RichTextLabel

func config(text, level, cost):
	if not textbox:
		await self.ready
	textbox.add_text(text)
	textbox.add_text("/n")
	textbox.add_text(level)
	textbox.add_text(cost)
	

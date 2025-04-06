extends Control
class_name UpgradeTooltip
@onready var desc_label = $Panel/MarginContainer/VBoxContainer/Description	
@onready var cost_label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Cost	
@onready var level_label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Level	


func config(desc, level, cost):
	desc_label.clear()
	cost_label.clear()
	level_label.clear()
	desc_label.append_text("[color=white]%s[/color]" % [desc])
	cost_label.append_text("[color=yellow]%s[/color]" % [cost])
	level_label.append_text("[color=red]%s[/color]" % [level])

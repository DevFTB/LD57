@tool

extends Control
class_name UpgradeButton

@export var max_level = 0 :
	set(value):
		max_level = value
		$Label.text = str(current_level) + "/" + str(max_level)

@export var upgrade : Resource
@export var tier = 0
@export var dependecies: Dictionary[UpgradeButton, int]
@onready var panel = $Button/Panel
@onready var label = $Label
var current_level = 0

func _ready() -> void:
	label.text = str(current_level) + "/" + str(max_level)	

func _on_pressed():
	if can_upgrade(): 
		upgrade.add_level(tier)
		current_level = upgrade.levels[tier]
	label.text = str(current_level) + "/" + str(max_level)	

func can_upgrade():
	# TODO: Check money is enough
	if current_level == 0 or upgrade.levels[tier] < max_level:
		if dependecies.size() == 0:
			return true
		for dependency in dependecies:
			if dependency.current_level >= dependecies[dependency]:
				return true
		
func _draw():
	for dependency in dependecies:
		draw_line(dependency.get_position()+Vector2(dependency.size.x/2,0)-self.get_position(), Vector2(self.get_size().x/2, self.get_size().y), Color.BLACK, 3)

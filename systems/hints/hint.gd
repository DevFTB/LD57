extends Node
class_name Hint

@export_multiline var hint_text: String = ""
@export var repeating: bool = false
@export var hint_box: HintDisplayBox
@export var poll_time: float = 2.0

var times_shown := 0
var timer: Timer

func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = 2.0
	timer.timeout.connect(poll)

	add_child(timer)
	timer.start()

func poll() -> void:
	if (not repeating and times_shown < 1) or repeating:
		if are_conditions_satisfied() and not hint_box.busy:
			display()

	timer.start()
	
func are_conditions_satisfied() -> bool:
	return true

func display() -> void:
	hint_box.show_hint(self)
	times_shown += 1

extends ProgressBar

@export var timer: Timer

func _ready() -> void:
    update()

func _process(_delta: float) -> void:
    if timer:
        update()

func update() -> void:
    max_value = timer.wait_time
    value = timer.time_left

extends Camera2D

var ZoomMin = Vector2(0.25,0.25)
var ZoomMax = Vector2(2.5,2.5)
var ZoomSpd = Vector2(0.3,0.3)
var PanSpeedKey = 8
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if event.is_action_pressed("select_bomb_1"):
		if zoom > ZoomMin:
			zoom -= ZoomSpd
	if event.is_action_pressed("select_bomb_2"):
		if zoom < ZoomMax:
			zoom +=ZoomSpd
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_pressed("jump"):
		position.y -= PanSpeedKey
	if Input.is_action_pressed("move_down"):
		position.y += PanSpeedKey
	if Input.is_action_pressed("move_left"):
		position.x -= PanSpeedKey
	if Input.is_action_pressed("move_right"):
		position.x += PanSpeedKey
	pass

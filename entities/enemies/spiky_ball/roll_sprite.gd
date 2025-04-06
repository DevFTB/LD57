extends Sprite2D

var enemy : Enemy

@export var rotation_speed: int = 4
@export var roll_accel: int = 8
@onready var speed = 0

func _ready() -> void:
	await owner.ready
	enemy = owner as Enemy
	var speed = 0
	assert(enemy != null, "The EnemyState state type must be used only in the enemy scene. It needs the owner to be a Enemy node.")

func _physics_process(delta: float) -> void:
	#if enemy.velocity.x == 0 or (speed < 0 and enemy.velocity.x > 0) or (speed > 0 and enemy.velocity.x < 0):
		#speed = 0 
	if (speed < 0 and enemy.velocity.x > 0) or (speed > 0 and enemy.velocity.x < 0):
		speed = clamp(speed, -rotation_speed/4, rotation_speed/4)
	if enemy.velocity.x != 0:
		speed = clamp(speed + signf(enemy.velocity.x) * roll_accel * delta, -rotation_speed, rotation_speed)
	
	rotation_degrees += speed
	#rotation_degrees += enemy.velocity.x * rotation_speed * delta	

class_name EnemyState extends State

const IDLE = "Idle"
const FLYING = "Flying"
const ATTACKING = "Attacking"
const RUNNING = "Running"
const JUMPING = "Jumping"
const FALLING = "Falling"
const KNOCKED_BACK = "KnockedBack"
const RANGED_ATTACKING = "RangedAttacking"

var enemy : Enemy
var player : Player

func _ready() -> void:
	await owner.ready
	enemy = owner as Enemy
	assert(enemy != null, "The EnemyState state type must be used only in the enemy scene. It needs the owner to be a Enemy node.")
	player = get_tree().get_first_node_in_group("player")

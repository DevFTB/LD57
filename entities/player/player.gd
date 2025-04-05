extends GroundedCharacterController
class_name Player

class ThrowInitiatedEventData:
    var position: Vector2
    var impulse: Vector2
    var bomb_scene: PackedScene
    

signal interacted
signal throw_initiated(data: ThrowInitiatedEventData)

const THROWABLE_BOMB := preload("uid://do0g7votir2b4")

@export var throw_force_curve: Curve

@onready var inventory_component: InventoryComponent = $InventoryComponent

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    
    if Input.is_action_just_pressed("interact"):
        interacted.emit()
    
    if Input.is_action_just_pressed("throw"):
        initiate_throw()

func initiate_throw() -> void:
    var direction := global_position.direction_to(get_global_mouse_position())

    var data := ThrowInitiatedEventData.new()
    data.position = global_position
    data.impulse = direction.normalized() * throw_force_curve.sample_baked(1.0)
    data.bomb_scene = THROWABLE_BOMB

    throw_initiated.emit(data)

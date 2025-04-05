extends GroundedCharacterController
class_name Player

signal interacted

@onready var inventory_component: InventoryComponent = $InventoryComponent

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    
    if Input.is_action_just_pressed("interact"):
        interacted.emit()
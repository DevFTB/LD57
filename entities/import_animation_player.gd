## A tool script to generate Animations from a spritesheet for the player.
@tool
extends AnimationPlayer

enum Direction {
	DOWN_RIGHT, UP_LEFT, DOWN_LEFT, UP_RIGHT,
}

const FLIP_TARGET := {
	Direction.DOWN_RIGHT: Direction.DOWN_LEFT,
	Direction.UP_LEFT: Direction.UP_RIGHT
}

const direction_strings := {
	Direction.DOWN_RIGHT: "down_right",
	Direction.DOWN_LEFT: "down_left",
	Direction.UP_LEFT: "up_left",
	Direction.UP_RIGHT: "up_right"
}
@export var sprite_path: String
@export var action_name: String = "default"
@export var sprite_sheet: Texture2D
@export var size: Vector2i
@export var time_spacing: float = 0.1
@export var direction_order: Array[Direction] = []
@export var generate_flips: bool = true

@export_subgroup("Custom Frame Order")
@export var custom_frame_order_enabled := false
@export var custom_frame_order: Array[int] = []

@export_tool_button("Generate!", "AnimationLibrary") var action := load_animations

func load_animations() -> void:
	var anim_library := get_animation_library("")

	if direction_order.size() == 0:
		var anim := _generate_animation_direction(0)
		anim_library.add_animation(action_name, anim)
	else:
		for direction_index in range(direction_order.size()):
			var direction := direction_order[direction_index]
			
			var animation_name := str(action_name, "_", direction_strings[direction])
			var anim := _generate_animation_direction(direction_index)
			anim_library.add_animation(animation_name, anim)
			
			if generate_flips:
				var flipped_animation_name := str(action_name, "_", direction_strings[FLIP_TARGET[direction]])
				var flipped_anim := _generate_animation_direction(direction_index, true)

				anim_library.add_animation(flipped_animation_name, flipped_anim)
			
	ResourceSaver.save(anim_library)

func _get_path(property: String) -> String:
	return str(sprite_path, ":", property)


func _generate_animation_direction(frame_coords_y: int, is_flipped: bool = false) -> Animation:
	var anim := Animation.new()
	anim.length = custom_frame_order.size() * time_spacing if custom_frame_order_enabled else size.x * time_spacing
	anim.loop_mode = Animation.LOOP_LINEAR
	
	var texture_track_id := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(texture_track_id, _get_path("texture"))
	anim.track_insert_key(texture_track_id, 0.0, sprite_sheet)
	
	var hf_track_id := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(hf_track_id, _get_path("hframes"))
	anim.track_insert_key(hf_track_id, 0.0, size.x)
	
	var vf_track_id := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(vf_track_id, _get_path("vframes"))
	anim.track_insert_key(vf_track_id, 0.0, size.y)
	
	var fh_track_id := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(fh_track_id, _get_path("flip_h"))
	anim.track_insert_key(fh_track_id, 0.0, is_flipped)
	
	var frame_coords_track_id := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(frame_coords_track_id, _get_path("frame_coords"))
	anim.track_set_interpolation_loop_wrap(frame_coords_track_id, true)
	
	anim.value_track_set_update_mode(frame_coords_track_id, Animation.UPDATE_DISCRETE)
	
	if custom_frame_order_enabled:
		var x := 0
		for frame in custom_frame_order:
			var value := Vector2i(frame, frame_coords_y)
			anim.track_insert_key(frame_coords_track_id, x * time_spacing, value)
			x += 1
	else:
		for x in range(size.x):
			var value := Vector2i(x, frame_coords_y)
			anim.track_insert_key(frame_coords_track_id, x * time_spacing, value)

	return anim

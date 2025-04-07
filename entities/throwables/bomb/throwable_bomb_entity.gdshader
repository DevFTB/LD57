shader_type canvas_item;

uniform vec4 solid_color : source_color;

void fragment() {
vec4 texture_color = texture(TEXTURE, UV);
    COLOR = vec4(mix(texture_color.rgb, solid_color.rgb, solid_color.a), texture_color.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

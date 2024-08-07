shader_type spatial;

instance uniform vec4 my_color;

void fragment() {
	ALBEDO = my_color.rgb;
}

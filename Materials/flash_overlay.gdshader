shader_type spatial;
render_mode cull_disabled;

instance uniform vec4 my_color;

void fragment() {
	ALBEDO = my_color.rgb;
	ALPHA = my_color.a;
}

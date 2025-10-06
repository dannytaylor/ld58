shader_type canvas_item;
uniform float speed = 0.2;
uniform float size = 4.0;
uniform float alpha = 0.1;

void fragment() {
	vec2 uv = vec2(UV.x*-4.0,UV.y*4.0)*size/2.0+TIME*speed;
	COLOR = texture(TEXTURE, uv); //read from texture
	COLOR.w = alpha;
}
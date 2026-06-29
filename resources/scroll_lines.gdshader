shader_type canvas_item;

uniform float slowdown = 7.;
uniform vec4 colorA:source_color;
uniform vec4 colorB:source_color;

void fragment() {
	COLOR = mod(10. * (UV.x + UV.y - (TIME / slowdown)), 2.) > 1. ? colorA : colorB;
}

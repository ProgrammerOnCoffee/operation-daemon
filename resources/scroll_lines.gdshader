shader_type canvas_item;

uniform float slowdown = 7.;
uniform vec4 colorA:source_color;
uniform vec4 colorB:source_color;

void fragment() {
	// Called for every pixel the material is visible on.
	
	if (mod(10. * (UV.x + UV.y - (TIME / slowdown)), 2.) > 1.)
	{
		COLOR = colorA;
	}
	else{COLOR = colorB;}
	
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

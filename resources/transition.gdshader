shader_type canvas_item;

#define MAX_BAR_COUNT 48

/** The number of individual bars in the transition. */
uniform int bar_count: hint_range(1, MAX_BAR_COUNT) = 24;
/** The current aspect ratio of the game window. */
uniform float ratio = 1.0;
/** The rotation of the transition effect. */
uniform float angle;
/** If [code]true[/code], the shader will transtition from hidden to visible. */
uniform bool inverted;
/** Each bar's direction of travel. */
uniform bool[MAX_BAR_COUNT] directions;
/** Each bar's UV cutoff where pixels will be transparent. */
uniform float[MAX_BAR_COUNT] cutoffs;

/** Rotates point [param p] by angle [param a]. */
vec2 rotate(vec2 p, float a) {
	p -= vec2(0.5);
	float sine = sin(a);
	float cosi = cos(a);
	return vec2(
		p.x * cosi - p.y * sine,
		p.x * sine + p.y * cosi
	) + vec2(0.5);
}

void fragment() {
	vec2 uv = rotate((SCREEN_UV / vec2(1.0, ratio)), angle);
	int index = int(floor(mod(uv.x, 1.0) * float(bar_count)));
	COLOR.a *= (directions[index] ? 1.0 - uv.y : uv.y) >= cutoffs[index] ? (inverted ? 0.0 : 1.0) : (inverted ? 1.0 : 0.0);
}

shader_type canvas_item;

/** The color of the currently damaged portion of the health bar. */
uniform vec3 health_c: source_color = vec3(0.80, 0.24, 0.24);
/** The color of the currently damaged portion of the health bar. */
uniform vec3 damaged_c: source_color = vec3(0.94, 0.40, 0.09);

/** The number of individual cells that will appear in the health bar. */
instance uniform int cells = 20;
/** The width of the gap between cells. */
instance uniform float gap_width = 6.0;
/** The width of the slant, or the amount that the bottom part of the health bar will be offset from the top. */
instance uniform float slant_width = 6.0;
/** The current width of the bar, in pixels. */
instance uniform float bar_width = 243.0;

/** The entity's current health, as a percentage of their max health. */
instance uniform float health_p: hint_range(0.0, 1.0) = 1.0;
/** The current portion of the health bar that should temporarily appear damaged. */
instance uniform float damaged_p: hint_range(0.0, 1.0) = 1.0;

/** The size of each cell, in UV coordinates. */
varying float cell_uv_width;
/** [member slant_width] in UV coordinates. */
varying float slant_uv_width;


void vertex() {
	cell_uv_width = 1.0 / float(cells);
	slant_uv_width = slant_width / bar_width;
}


void fragment() {
	// Remap UV.x to the slant_uv_width to 1.0 range, and adjust it based on UV.y to account for slant.
	float x = (UV.x - slant_uv_width) / (1.0 - slant_uv_width) + slant_uv_width * UV.y;
	// Color bar
	COLOR.rgb = x <= health_p ? x > damaged_p ? damaged_c : health_c : vec3(0);
	
	float cell_dist = abs(mod(x - TIME / bar_width * 3.0 + cell_uv_width / 2.0, cell_uv_width) + cell_uv_width / 2.0 - cell_uv_width);
	/** The width of the gap between cells, in UV coordinates. */
	float gap_uv_width = SCREEN_PIXEL_SIZE.x * gap_width;
	/** The UV coordinate of where the health bar should end. */
	float end_p = health_p - gap_uv_width;
	COLOR.a *= min(abs((x + gap_uv_width) - (damaged_p + gap_uv_width)) / gap_uv_width * 2.0, 1.0);
	COLOR.a *= x <= gap_uv_width ? 1.0 - min(abs(x - gap_uv_width), 1.0) / gap_uv_width : 1.0;
	COLOR.a *= x >= end_p ? 1.0 - min(abs(x - end_p), 1.0) / gap_uv_width : 1.0;
	COLOR.a *= cell_dist < SCREEN_PIXEL_SIZE.x * gap_width ? min(cell_dist / gap_uv_width, 1.0) : 1.0;
}

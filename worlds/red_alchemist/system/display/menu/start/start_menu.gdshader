shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.95, 0.72, 0.54, 1.0);
uniform vec4 mid_color : source_color = vec4(0.72, 0.40, 0.27, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.34, 0.12, 0.09, 1.0);

uniform float bevel_strength = 0.30;
uniform float shine_strength = 0.22;
uniform float shine_position = 0.30;
uniform float shine_width = 0.07;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 original = tex * COLOR;

	float y = UV.y;

	// Three-stage copper gradient.
	vec3 metal;
	if (y < 0.5) {
		metal = mix(top_color.rgb, mid_color.rgb, y * 2.0);
	} else {
		metal = mix(mid_color.rgb, bottom_color.rgb, (y - 0.5) * 2.0);
	}

	// Thin reflected-light band.
	float shine = exp(
		-pow((y - shine_position) / shine_width, 2.0)
	) * shine_strength;

	metal += shine;

	// Fake engraved/beveled edges.
	vec2 px = TEXTURE_PIXEL_SIZE * 1.5;

	float alpha_here = tex.a;
	float alpha_top_left =
		texture(TEXTURE, UV - px).a;
	float alpha_bottom_right =
		texture(TEXTURE, UV + px).a;

	float bevel_light =
		clamp(alpha_here - alpha_top_left, 0.0, 1.0);

	float bevel_dark =
		clamp(alpha_here - alpha_bottom_right, 0.0, 1.0);

	float bevel =
		1.0
		+ bevel_light * bevel_strength
		- bevel_dark * bevel_strength * 0.7;

	// Multiply the existing color so dark shadows remain dark.
	vec3 final_rgb = original.rgb * metal * bevel;

	COLOR = vec4(final_rgb, original.a);
}
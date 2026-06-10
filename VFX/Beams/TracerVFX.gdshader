shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D noise:source_color,repeat_enable;
uniform vec4 gradientRemap = vec4(0.708, -2.683, 0, 0.264);
uniform vec4 beamRemap = vec4(0.404, 1.12, 1, 200.0);
uniform vec4 color1:source_color;
uniform vec4 color2:source_color;
uniform vec3 scale = vec3(1.0, 50.0, 0);
uniform float master_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float threshold = 0.993;
uniform float offset = 1.5;
uniform float glow_strength = 5.0;

// 1. Create the bridge (varying)
varying float particle_life;

void vertex() {
	// 2. Grab the life ratio (0 to 1) and pass it to the fragment stage
	particle_life = INSTANCE_CUSTOM.y;
}

vec3 blend_linear_light(vec3 base, vec3 blend, float opacity) {
	return mix(blend, blend + (2.0 * base - 1.0), opacity);
}

float map(float value, float from_min, float from_max, float to_min, float to_max) {
	return abs(from_max - from_min) > 0.0001 ? 
		to_min + (from_min > from_max ? 1.0 - smoothstep(from_max, from_min, value) : smoothstep(from_min, from_max, value)) * (to_max - to_min) : 
		0.0;
}

void fragment() {
	// 3. Use the varying here. We subtract from 1.0 so it fades OUT.
	float life_fade = 1.0 - particle_life;
	
	vec2 uv = vec2((UV.x*2.0)-1.0, (UV.y*2.0)-1.0);
	vec3 n = texture(noise, uv+vec2(TIME*offset, 0)).rgb;
	float remap = map(uv.x, gradientRemap.x, gradientRemap.y, gradientRemap.z, gradientRemap.w);
	
	vec3 col = (blend_linear_light(n, vec3(uv.xy, 1), remap));
	vec3 scaled_col = col * scale;
	float len = length(scaled_col);
	
	float clamped = len < threshold ? 1.0 : 0.0;
	
	vec4 final_color = mix(color1, color2, clamped);
	
	float scale_factor = map(uv.x, beamRemap.x, beamRemap.y, beamRemap.z, beamRemap.w);
	
	ALBEDO = final_color.rgb;
	
	// 4. Apply the fade to Alpha and Emission
	ALPHA = final_color.a * life_fade * master_alpha;
	EMISSION = final_color.rgb * glow_strength * life_fade * master_alpha;
}
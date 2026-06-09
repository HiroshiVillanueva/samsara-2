// DASTER on YT - Wind Waker style water with custom foam color
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 water_color : source_color = vec4(0.20, 0.50, 0.80, 1.0);
uniform vec4 depth_color : source_color = vec4(0.05, 0.15, 0.35, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);  // ← NEW
uniform float noise_blur = 0.015;        // ← Main blur strength (0.0 = sharp, 0.03 = very soft)
uniform int blur_samples = 8;            // ← Quality vs performance (4 = fast, 12 = smoother)

uniform sampler2D noise_tex_a;
uniform sampler2D noise_tex_b;

uniform float noise_a_speed = 0.3;
uniform vec2 noise_a_dir = vec2(1.0, 0.2);
uniform float noise_a_scale = 3.0;
uniform float noise_a_amount = 1.0;
uniform float noise_a_threshold = 0.85;

uniform float noise_b_speed = 0.6;
uniform vec2 noise_b_dir = vec2(-0.6, 0.4);
uniform float noise_b_scale = 4.0;
uniform float noise_b_amount = 0.6;
uniform float noise_b_threshold = 0.75;
uniform float noise_b_opacity = 0.5;

uniform float edge_width = 0.16;
uniform float edge_soft = 0.02;
uniform float edge_anim_speed = 1.2;
uniform float edge_anim_amount = 0.025;

uniform float foam_brightness = 1.0;      // still useful for intensity
uniform float overall_opacity = 1.0;

vec2 move_uv(vec2 uv, vec2 dir, float speed, float time, float scale) {
    vec2 d = normalize(dir);
    return uv * scale + d * time * speed;
}

void fragment() {
    vec2 uv = UV;
    float t = TIME;

    // Depth gradient
    vec2 centered = uv - vec2(0.5);
    float dist = length(centered);
    float max_dist = 0.70710678;
    float dist_n = clamp(dist / max_dist, 0.0, 1.0);
    float depth_w = smoothstep(0.0, 1.0, dist_n);
    
    vec3 base = mix(depth_color.rgb, water_color.rgb, depth_w);

    // Noise A
    vec2 uv_a = move_uv(uv, noise_a_dir, noise_a_speed, t, noise_a_scale);
    float nA = texture(noise_tex_a, uv_a).r;
    float foamA = smoothstep(noise_a_threshold, 1.0, nA) * noise_a_amount;

    // Noise B
    vec2 uv_b = move_uv(uv, noise_b_dir, noise_b_speed, t, noise_b_scale);
    float nB = texture(noise_tex_b, uv_b).r;
    float foamB_raw = smoothstep(noise_b_threshold, 1.0, nB) * noise_b_amount;
    float foamB = foamB_raw * noise_b_opacity;

    float interior_foam = clamp(foamA + foamB, 0.0, 1.0);

    // Edge foam
    float edge_pulse = sin(t * edge_anim_speed) * edge_anim_amount;
    float edge_width_anim = edge_width + edge_pulse;
    float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    float edge_mask = smoothstep(edge_width_anim, edge_width_anim + edge_soft, edge_dist);
    float edge_foam = 1.0 - edge_mask;

    float foam_final = max(interior_foam, edge_foam);

    // Final color mixing with new foam color
    vec3 final_col = mix(base, foam_color.rgb * foam_brightness, foam_final);

    ALBEDO = final_col;
    ALPHA = overall_opacity;
    EMISSION = foam_color.rgb * (foam_final * 0.2);   // emission also uses new color
    ROUGHNESS = 0.35;
    METALLIC = 0.0;
}
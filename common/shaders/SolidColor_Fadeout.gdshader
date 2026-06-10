shader_type spatial;
// billboard_keep_scale is great for particles so they always face the camera
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform sampler2D main_texture : source_color; // Your PNG goes here
uniform vec4 primary_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float fade_start_percent = 0.1; 
uniform float hue_shift_amount : hint_range(0.0, 1.0) = 0.2;

varying float particle_age;
varying float particle_id;

// Helper to shift hue
vec3 apply_hue(vec3 color, float shift) {
    vec3 k = vec3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(shift * 6.28318);
    return color * cosAngle + cross(k, color) * sin(shift * 6.28318) + k * dot(k, color) * (1.0 - cosAngle);
}

void vertex() {
    particle_age = INSTANCE_CUSTOM.y;
    particle_id = float(INSTANCE_ID);
}

void fragment() {
    // 1. Sample the PNG texture
    vec4 tex_color = texture(main_texture, UV);
    
    // 2. Calculate the age-based fade
    float age_mask = 1.0 - smoothstep(fade_start_percent, 1.0, particle_age);
    
    // 3. Apply Hue Shift to the texture's RGB
    float shift = fract(particle_id * 0.12345) * hue_shift_amount;
    vec3 color_with_hue = apply_hue(tex_color.rgb * primary_color.rgb, shift);
    
    // 4. Output final color
    ALBEDO = color_with_hue;
    
    // 5. Combine texture alpha, tint alpha, and our fade logic
    // This ensures only the "open parts" of the PNG are visible
    ALPHA = tex_color.a * primary_color.a * age_mask;
    
    // Alpha scissor (Optional): If you want hard edges like a mask, uncomment below:
    // ALPHA_SCISSOR_THRESHOLD = 0.1;
}
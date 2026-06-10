shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled;

uniform vec3 line_color : source_color = vec3(1.0, 1.0, 1.0);

// Set close to 0.5 so it reaches the edge of the quad mesh
uniform float outer_radius : hint_range(0.0, 0.5) = 0.48; 
// Minimum thickness of the line
uniform float base_thickness : hint_range(0.001, 0.2) = 0.05; 

// Squiggle settings
uniform float noise_frequency : hint_range(0.0, 30.0) = 8.0;
uniform float noise_amplitude : hint_range(0.0, 0.3) = 0.08;
uniform float animation_speed : hint_range(0.0, 10.0) = 2.0;

void fragment() {
    // 1. Shift UVs so (0,0) is in the center of the mesh
    vec2 centered_uv = UV - vec2(0.5);
    
    // 2. Get polar coordinates
    float dist = length(centered_uv);
    float angle = atan(centered_uv.y, centered_uv.x);
    
    // 3. Generate procedural noise (values will range from approx -0.875 to 0.875)
    float noise = sin(angle * noise_frequency + TIME * animation_speed) * 0.5;
    noise += sin(angle * noise_frequency * 2.1 - TIME * animation_speed * 1.3) * 0.25;
    noise += sin(angle * noise_frequency * 3.7 + TIME * animation_speed * 0.8) * 0.125;
    
    // Normalize the noise to a 0.0 to 1.0 range so it only pushes inwards
    float normalized_noise = (noise + 0.875) / 1.75;
    
    // 4. Calculate the inner radius (outer edge minus thickness minus the squiggly noise)
    float inner_radius = outer_radius - base_thickness - (normalized_noise * noise_amplitude);
    
    // 5. Create two separate masks using smoothstep for anti-aliasing
    float blur = 0.005;
    // Mask 1: A perfect, smooth circle on the outside
    float outside_mask = 1.0 - smoothstep(outer_radius - blur, outer_radius + blur, dist);
    // Mask 2: A squiggly, noisy circle on the inside
    float inside_mask = smoothstep(inner_radius - blur, inner_radius + blur, dist);
    
    // 6. Combine the masks (pixel must be inside the outer edge AND outside the inner edge)
    float alpha = outside_mask * inside_mask;
    
    ALBEDO = line_color;
    ALPHA = alpha;
}
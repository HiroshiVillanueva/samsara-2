shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 outline_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);  // ← Now bright cyan, matching the beam
uniform float outline_width : hint_range(0.0, 0.5) = 0.05;

void vertex() {
    // Push the vertices outward along their normals
    VERTEX += NORMAL * outline_width;
}

void fragment() {
    ALBEDO = outline_color.rgb;
    // Optional: make it a tiny bit brighter for that "glow" feel
    EMISSION = outline_color.rgb * 0.5;
}
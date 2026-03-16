// dirt_clean_surface.gdshader
// Shader for cleanable surfaces.
// Lerps between a "clean" and "dirty" albedo based on the dirt_amount uniform.
// CleanableSurface.gd updates dirt_amount every frame.
//
// Apply this shader to a ShaderMaterial on the toilet / floor / wall meshes.

shader_type spatial;

// 0.0 = fully clean, 1.0 = fully dirty
uniform float dirt_amount : hint_range(0.0, 1.0) = 1.0;

uniform vec4 clean_color : source_color = vec4(0.92, 0.92, 0.94, 1.0);
uniform vec4 dirty_color : source_color = vec4(0.35, 0.28, 0.20, 1.0);

// Optional texture overlays
uniform sampler2D clean_texture : source_color, hint_default_white;
uniform sampler2D dirt_texture  : source_color, hint_default_white;

uniform float roughness_clean : hint_range(0.0, 1.0) = 0.25;
uniform float roughness_dirty : hint_range(0.0, 1.0) = 0.90;

void fragment() {
    vec4 clean_tex = texture(clean_texture, UV) * clean_color;
    vec4 dirty_tex = texture(dirt_texture,  UV) * dirty_color;

    // Blend between clean and dirty based on dirt_amount
    ALBEDO    = mix(clean_tex.rgb, dirty_tex.rgb, dirt_amount);
    ROUGHNESS = mix(roughness_clean, roughness_dirty, dirt_amount);
    METALLIC  = 0.0;
}

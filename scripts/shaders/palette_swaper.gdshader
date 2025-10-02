shader_type canvas_item;

// Textura con la paleta original (colores a buscar)
uniform sampler2D original_palette;
// Textura con la nueva paleta (colores de reemplazo)
uniform sampler2D new_palette;
// Textura con la paleta anterior (para transiciones)
uniform sampler2D old_palette;

// Cantidad de colores en las paletas
uniform int palette_size = 4;
// Sensibilidad para coincidencia de colores
uniform float color_tolerance = 0.1;
// Progreso de transición (0 = old_palette, 1 = new_palette)
uniform float blend_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    vec4 color_from_old = original_color;
    vec4 color_from_new = original_color;

    for (int i = 0; i < palette_size; ++i) {
        vec2 palette_uv = vec2(float(i) / float(palette_size - 1), 0.0);
        vec4 palette_color = texture(original_palette, palette_uv);

        float color_distance = distance(original_color.rgb, palette_color.rgb);

        if (color_distance < color_tolerance) {
            color_from_old = texture(old_palette, palette_uv);
            color_from_new = texture(new_palette, palette_uv);
            break;
        }
    }

    vec4 final_color = mix(color_from_old, color_from_new, blend_amount);
    final_color.a = original_color.a;
    COLOR = final_color;
}

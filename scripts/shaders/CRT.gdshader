/*
CRT Shader – Mobile Lite
Basado en Godot Shaders (CC0) por @c64cosmin et al.
Optimizado para gama baja: 1 texture sample, sin ruido, sin aberración.
Efectos: warp, scanlines, vignette.
*/

shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

uniform vec2  resolution         = vec2(480.0, 270.0);
uniform float warp_amount        : hint_range(0.0, 2.0)  = 0.5;
uniform float scan_line_amount   : hint_range(0.0, 1.0)  = 0.8;
uniform float vignette_amount    : hint_range(0.0, 2.0)  = 0.3;
uniform float vignette_intensity : hint_range(0.0, 1.0)  = 0.4;

// --- Warp ---
// Curvatura barrel sin trig: solo dot products y potencias.
vec2 warp(vec2 uv) {
    vec2 d = uv - 0.5;
    float d2 = dot(d, d);
    return uv + d * (d2 * d2 * warp_amount);
}

// --- Vignette ---
// Igual que el original, pero siempre activa (evita branch por uniform).
float vignette(vec2 uv) {
    uv *= 1.0 - uv;
    return pow(uv.x * uv.y * 15.0, vignette_intensity * vignette_amount);
}

void fragment() {
    vec2 pos = warp(SCREEN_UV);

    vec3 clr;

    // Píxeles fuera del área warpeada → negro
    if (max(abs(pos.x - 0.5), abs(pos.y - 0.5)) > 0.5) {
        clr = vec3(0.0);
    } else {
        clr = texture(SCREEN_TEXTURE, pos).rgb;

        float scan = sin(pos.y * resolution.y * PI) * 0.5 + 0.5;
        clr *= mix(1.0, scan, scan_line_amount);
        clr *= 1.0 + scan_line_amount * 0.5;

        clr *= vignette(pos);
    }

    COLOR = vec4(clr, 1.0);
}
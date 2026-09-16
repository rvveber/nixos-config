const vec3 fhudAccent = vec3(@accent@) / 255.0;
const float fhudStrength = @strength@;
const float fhudDepth = @depth@;
const float fhudPanelOpacity = @panelOpacity@;
const float fhudPanelTint = @panelTint@;

float fhudLuminance(vec4 pixel) {
    return dot(pixel.rgb / max(pixel.a, 0.001), vec3(0.2126, 0.7152, 0.0722));
}

float fhudNeutral(vec3 color) {
    float chroma = max(color.r, max(color.g, color.b)) - min(color.r, min(color.g, color.b));
    return 1.0 - smoothstep(0.04, 0.16, chroma);
}

float fhudSampleLuminance(vec2 offset) {
    return fhudLuminance(x_TextureOffset(offset));
}

float fhudAxis(vec2 offset, vec2 across, vec2 along, float value) {
    float before = fhudSampleLuminance(offset - across);
    float after = fhudSampleLuminance(offset + across);
    bool negative = abs(value - before) > abs(value - after);
    vec2 edge = offset + (negative ? -across : across);
    float neighbor = negative ? before : after;
    float continuity = max(abs(value - fhudSampleLuminance(offset + along)),
                           abs(value - fhudSampleLuminance(offset - along)));
    continuity = max(continuity, max(abs(neighbor - fhudSampleLuminance(edge + along)),
                                    abs(neighbor - fhudSampleLuminance(edge - along))));
    return smoothstep(0.012, 0.065, abs(value - neighbor)) * (1.0 - smoothstep(0.008, 0.025, continuity));
}

float fhudLines(vec2 offset) {
    vec4 center = x_TextureOffset(offset);
    float value = fhudLuminance(center);
    float horizontal = fhudAxis(offset, vec2(0.0, 1.0), vec2(12.0, 0.0), value);
    float vertical = fhudAxis(offset, vec2(1.0, 0.0), vec2(0.0, 12.0), value);
    return max(horizontal, vertical) * center.a * fhudNeutral(center.rgb / max(center.a, 0.001));
}

void windowShader(inout vec4 color) {
    vec3 original = color.rgb / max(color.a, 0.001);
    float luminance = fhudLuminance(color);
    float neutral = fhudNeutral(original);
    float panel = neutral * (1.0 - smoothstep(0.25, 0.55, luminance));
    vec3 tinted = fhudAccent * luminance / dot(fhudAccent, vec3(0.2126, 0.7152, 0.0722));
    vec3 ink = mix(original, tinted, panel * fhudPanelTint);
    float settle = smoothstep(0.0, 1.0, x_FadeIn);
    vec2 offset = vec2(1.0, -1.0) * fhudDepth * (3.0 - 2.0 * settle);
    float line = fhudLines(vec2(0.0));
    float echo = fhudLines(offset);
    float entrance = 1.0 - smoothstep(0.0, 0.25, x_FadeIn);
    entrance += smoothstep(0.25, 0.40, x_FadeIn) * (1.0 - smoothstep(0.50, 0.75, x_FadeIn));
    vec2 size = max(x_WindowSize, vec2(1.0));
    float border = smoothstep(0.0, 3.0, min(min(x_PixelPos.x, size.x - x_PixelPos.x), min(x_PixelPos.y, size.y - x_PixelPos.y)));
    float geometry = neutral * border;
    ink *= 1.0 - line * entrance * fhudStrength;
    ink = mix(ink, max(ink, fhudAccent * 0.7), line * geometry * fhudStrength);
    ink += fhudAccent * echo * geometry * fhudStrength * settle;
    color.a *= mix(1.0, fhudPanelOpacity, panel);
    color.rgb = clamp(ink, vec3(0.0), vec3(1.0)) * color.a;
}

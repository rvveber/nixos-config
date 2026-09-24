const vec3 fhudAccent = vec3(@accent@) / 255.0;
const float fhudStrength = @strength@;
const float fhudDepth = @depth@;
const float fhudPanelOpacity = @panelOpacity@;
const float fhudPanelTint = @panelTint@;
const int fhudLineRadius = 16;
const bool fhudDebugRectangles = false;
uniform int fhudRectangleCount;
uniform vec4 fhudRectangleBounds[64];

bool fhudInside(vec2 offset) {
    vec2 position = x_PixelPos - offset;
    return all(greaterThanEqual(position, vec2(0.5))) &&
           all(lessThanEqual(position, x_WindowSize - vec2(0.5)));
}

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
    float contrast = abs(value - neighbor);
    if (contrast < 0.035 || !fhudInside(edge))
        return 0.0;

    vec2 end = along * float(fhudLineRadius);
    if (!fhudInside(offset + end) || !fhudInside(offset - end) ||
        !fhudInside(edge + end) || !fhudInside(edge - end))
        return 0.0;

    // Reject short strokes first, then verify every intervening pixel.
    float continuity = 0.0;
    for (int i = fhudLineRadius; i > 0; --i) {
        vec2 step = along * float(i);
        continuity = max(continuity, max(abs(value - fhudSampleLuminance(offset + step)),
                                         abs(value - fhudSampleLuminance(offset - step))));
        continuity = max(continuity, max(abs(neighbor - fhudSampleLuminance(edge + step)),
                                         abs(neighbor - fhudSampleLuminance(edge - step))));
        if (continuity > 0.018)
            return 0.0;
    }
    return smoothstep(0.035, 0.075, contrast) * (1.0 - smoothstep(0.006, 0.018, continuity));
}

float fhudLines(vec2 offset) {
    vec4 center = x_TextureOffset(offset);
    if (!fhudInside(offset) || center.a < 0.01 || fhudNeutral(center.rgb / max(center.a, 0.001)) < 0.01)
        return 0.0;
    float value = fhudLuminance(center);
    float horizontal = fhudAxis(offset, vec2(0.0, 1.0), vec2(1.0, 0.0), value);
    float vertical = fhudAxis(offset, vec2(1.0, 0.0), vec2(0.0, 1.0), value);
    return max(horizontal, vertical) * center.a * fhudNeutral(center.rgb / max(center.a, 0.001));
}

vec4 fhudRectangle() {
    vec4 result = vec4(0.0);
    for (int i = 0; i < min(fhudRectangleCount, 64); ++i) {
        vec4 bounds = fhudRectangleBounds[i];
        if (any(lessThan(x_TexCoord, bounds.xy)) || any(greaterThanEqual(x_TexCoord, bounds.zw)))
            continue;
        float hue = fract(dot(floor(bounds * 1024.0 + 0.5), vec4(0.1031, 0.11369, 0.13787, 0.17389)));
        vec3 tint = 0.5 + 0.5 * cos(6.2831853 * (hue + vec3(0.0, 0.3333, 0.6667)));
        vec2 edge = min(x_TexCoord - bounds.xy, bounds.zw - x_TexCoord) * x_WindowSize;
        float alpha = min(edge.x, edge.y) < 2.0 ? 0.8 : 0.3;
        result = vec4(tint, alpha);
    }
    return result;
}

void windowShader(inout vec4 color) {
    if (fhudDebugRectangles) {
        vec4 rectangle = fhudRectangle();
        color.rgb = mix(color.rgb, rectangle.rgb * color.a, rectangle.a);
        return;
    }
    vec3 original = color.rgb / max(color.a, 0.001);
    float luminance = fhudLuminance(color);
    float neutral = fhudNeutral(original);
    float panel = neutral * (1.0 - smoothstep(0.25, 0.55, luminance));
    vec3 tinted = fhudAccent * luminance / dot(fhudAccent, vec3(0.2126, 0.7152, 0.0722));
    vec3 ink = mix(original, tinted, panel * fhudPanelTint);
    float settle = smoothstep(0.0, 1.0, x_FadeIn);
    vec2 offset = vec2(1.0, -1.0) * fhudDepth;
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

const vec3 fhudAccent = vec3(@accent@) / 255.0;
const float fhudStrength = @strength@;
const float fhudDepth = @depth@;
const float fhudPanelOpacity = @panelOpacity@;
const float fhudPanelTint = @panelTint@;
const int fhudLineRadius = 16;
const bool fhudDebugRectangles = false;
const int fhudRectangleReach = 256;

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

vec2 fhudDebugTexel() {
    return x_WindowSize / max(vec2(textureSize(x_Tex, 0)), vec2(1.0));
}

// Debug-only search: sample source texels, including thin borders on scaled monitors.
bool fhudRectangleEdge(vec2 offset, vec2 across, vec2 along, float outside, float inside) {
    bool positive = true;
    bool negative = true;
    for (int i = 1; i < 12; ++i) {
        vec2 step = along * float(i);
        if (positive) {
            positive = fhudInside(offset + step) && fhudInside(offset - across + step) &&
                abs(fhudSampleLuminance(offset + step) - outside) < 0.018 &&
                abs(fhudSampleLuminance(offset - across + step) - inside) < 0.018;
        }
        if (negative) {
            negative = fhudInside(offset - step) && fhudInside(offset - across - step) &&
                abs(fhudSampleLuminance(offset - step) - outside) < 0.018 &&
                abs(fhudSampleLuminance(offset - across - step) - inside) < 0.018;
        }
        if (!positive && !negative)
            return false;
    }
    return true;
}
float fhudFindSide(vec2 direction) {
    vec2 texel = fhudDebugTexel();
    vec2 across = direction * texel;
    vec2 along = direction.yx * texel;
    float previous = fhudSampleLuminance(vec2(0.0));
    for (int i = 1; i <= fhudRectangleReach; ++i) {
        vec2 offset = across * float(i);
        if (!fhudInside(offset))
            return -1.0;
        float value = fhudSampleLuminance(offset);
        if (abs(value - previous) >= 0.035 && fhudRectangleEdge(offset, across, along, value, previous))
            return (float(i) - 0.5) * dot(abs(direction), texel);
        previous = value;
    }
    return -1.0;
}

bool fhudRectangleSide(vec2 start, vec2 end, vec2 inward) {
    vec2 texel = fhudDebugTexel();
    float length = length((end - start) / texel);
    vec2 along = (end - start) / length;
    inward *= texel;
    float reference = fhudSampleLuminance(start + along * 0.5 + inward * 0.5) -
                      fhudSampleLuminance(start + along * 0.5 - inward * 0.5);
    if (abs(reference) < 0.035)
        return false;
    for (int i = 0; i < 2 * fhudRectangleReach; ++i) {
        if (float(i) >= length)
            break;
        vec2 offset = start + along * (float(i) + 0.5);
        float contrast = fhudSampleLuminance(offset + inward * 0.5) -
                         fhudSampleLuminance(offset - inward * 0.5);
        if (contrast * sign(reference) < 0.035 || abs(contrast - reference) > 0.018)
            return false;
    }
    return true;
}

vec4 fhudRectangle() {
    float left = fhudFindSide(vec2(1.0, 0.0));
    if (left < 0.0) return vec4(0.0);
    float right = fhudFindSide(vec2(-1.0, 0.0));
    if (right < 0.0) return vec4(0.0);
    float top = fhudFindSide(vec2(0.0, 1.0));
    if (top < 0.0) return vec4(0.0);
    float bottom = fhudFindSide(vec2(0.0, -1.0));
    if (bottom < 0.0) return vec4(0.0);
    vec2 size = vec2(left + right, top + bottom) / fhudDebugTexel();
    // Capping the entire rectangle keeps the search result consistent across its interior.
    if (min(size.x, size.y) < 22.0 ||
        max(size.x, size.y) > float(fhudRectangleReach))
        return vec4(0.0);

    vec2 a = vec2(left, top);
    vec2 b = vec2(-right, top);
    vec2 c = vec2(-right, -bottom);
    vec2 d = vec2(left, -bottom);
    if (!fhudRectangleSide(a, b, vec2(0.0, -1.0)) ||
        !fhudRectangleSide(b, c, vec2(1.0, 0.0)) ||
        !fhudRectangleSide(c, d, vec2(0.0, 1.0)) ||
        !fhudRectangleSide(d, a, vec2(-1.0, 0.0)))
        return vec4(0.0);

    vec4 bounds = floor(vec4(x_PixelPos - a, x_PixelPos - c) / fhudDebugTexel().xyxy + 0.5);
    float hue = fract(dot(bounds, vec4(0.1031, 0.11369, 0.13787, 0.17389)));
    vec3 debugColor = 0.5 + 0.5 * cos(6.2831853 * (hue + vec3(0.0, 0.3333, 0.6667)));
    return vec4(debugColor, 0.35);
}

void windowShader(inout vec4 color) {
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
    if (fhudDebugRectangles && color.a > 0.99) {
        vec4 rectangle = fhudRectangle();
        ink = mix(ink, rectangle.rgb, rectangle.a);
    }
    color.a *= mix(1.0, fhudPanelOpacity, panel);
    color.rgb = clamp(ink, vec3(0.0), vec3(1.0)) * color.a;
}

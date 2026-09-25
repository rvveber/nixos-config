#pragma once

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <span>
#include <vector>

namespace Fhud {
struct CornerFit { float radius = 0.f, confidence = 0.f; };

// Bounds use texture coordinates; radii use source pixels. Order: TL, TR, BR, BL.
template<class Sample>
inline std::array<CornerFit, 4> fitSampledCorners(const Sample& sample, int width, int height,
                                                const std::array<float, 4>& bounds, float minimumContrast,
                                                const std::array<float, 4>& limits) {
    std::array<CornerFit, 4> result{};
    constexpr std::array<std::array<float, 2>, 5> directions{{
        {0.9659258f, 0.2588190f}, {0.8660254f, 0.5f}, {0.7071068f, 0.7071068f},
        {0.5f, 0.8660254f}, {0.2588190f, 0.9659258f}}};
    std::array<float, 5> distances{};
    for (size_t i = 0; i < directions.size(); ++i) {
        const float sum = directions[i][0] + directions[i][1];
        distances[i] = sum - std::sqrt(sum * sum - 1.f);
    }
    const float extent = std::min((bounds[2] - bounds[0]) * width, (bounds[3] - bounds[1]) * height);
    for (int corner = 0; corner < 4; ++corner) {
        const float maximumRadius = std::min(extent, limits[corner]);
        if (maximumRadius < 3.f) continue;
        const float sx = corner == 0 || corner == 3 ? 1.f : -1.f;
        const float sy = corner < 2 ? 1.f : -1.f;
        const float x = bounds[sx > 0 ? 0 : 2] * width, y = bounds[sy > 0 ? 1 : 3] * height;
        const auto transition = [&](int ray, float distance) {
            const auto direction = directions[ray];
            const auto outside = sample(x + sx * direction[0] * (distance - 0.65f), y + sy * direction[1] * (distance - 0.65f));
            const auto inside = sample(x + sx * direction[0] * (distance + 0.65f), y + sy * direction[1] * (distance + 0.65f));
            return std::array<float, 3>{inside[0] - outside[0], inside[1] - outside[1], inside[2] - outside[2]};
        };
        const auto magnitude = [](const std::array<float, 3>& delta) {
            return std::max({std::abs(delta[0]), std::abs(delta[1]), std::abs(delta[2])});
        };
        const auto background = sample(x + sx * 0.1767767f, y + sy * 0.1767767f);
        int seeds = 0;
        for (float distance = 1.25f; distance <= maximumRadius * distances[2]; distance += 0.5f) {
            const auto seed = transition(2, distance);
            const float strength = magnitude(seed);
            if (strength < minimumContrast || strength < magnitude(transition(2, distance - 0.5f)) ||
                strength <= magnitude(transition(2, distance + 0.5f))) continue;
            if (++seeds > 12) break;
            bool outside = true;
            const float tolerance = std::max({2.f, minimumContrast * 2.f, strength * 0.1f});
            for (float d = 0.75f; d < distance - 0.75f && outside; d += 0.5f) {
                const auto color = sample(x + sx * 0.7071068f * d, y + sy * 0.7071068f * d);
                for (int c = 0; c < 3; ++c) outside &= std::abs(color[c] - background[c]) <= tolerance;
            }
            if (!outside) continue;
            const float initialRadius = distance / distances[2];
            std::array<float, 5> observations{};
            int supported = 0;
            float numerator = 0.f, denominator = 0.f, signal = 0.f;
            for (int ray = 0; ray < 5; ++ray) {
                float best = 0.f, position = -1.f;
                for (float offset = -1.f; offset <= 1.f; offset += 0.5f) {
                    const float d = initialRadius * distances[ray] + offset;
                    if (d < 0.75f) continue;
                    const auto delta = transition(ray, d);
                    float agreement = 0.f;
                    for (int c = 0; c < 3; ++c) agreement += delta[c] * seed[c];
                    if (agreement <= 0.f) continue;
                    const float contrast = magnitude(delta);
                    if (contrast < magnitude(transition(ray, d - 0.5f)) * 0.98f ||
                        contrast < magnitude(transition(ray, d + 0.5f)) * 0.98f) continue;
                    const float score = contrast / (1.f + 0.15f * offset * offset);
                    if (contrast >= minimumContrast && score > best) { best = score; position = d; }
                }
                observations[ray] = position;
                if (position < 0.f) continue;
                ++supported;
                numerator += distances[ray] * position;
                denominator += distances[ray] * distances[ray];
                signal += std::min(1.f, best / strength);
            }
            if (supported < 5) continue;
            const float radius = numerator / denominator;
            if (radius < 3.f || radius > maximumRadius) continue;
            float squaredError = 0.f;
            for (int ray = 0; ray < 5; ++ray)
                if (observations[ray] >= 0.f) {
                    const float residual = observations[ray] - radius * distances[ray];
                    squaredError += residual * residual;
                }
            const float error = std::sqrt(squaredError / supported);
            if (error > 0.4f) continue;
            const float confidence = signal / 5.f * (1.f - error / 1.5f);
            if (confidence >= 0.65f && confidence > result[corner].confidence)
                result[corner] = {radius, confidence};
        }
    }
    // Adjacent circular arcs must fit between their independently measured tangencies.
    for (const auto pair : {std::array<int, 2>{0, 1}, {1, 2}, {2, 3}, {3, 0}}) {
        const float extent = pair[0] % 2 == 0 ? (bounds[2] - bounds[0]) * width : (bounds[3] - bounds[1]) * height;
        if (result[pair[0]].radius + result[pair[1]].radius > extent + 1.f) {
            const int weaker = result[pair[0]].confidence < result[pair[1]].confidence ? pair[0] : pair[1];
            result[weaker] = {};
        }
    }
    return result;
}

inline std::array<CornerFit, 4> fitCorners(std::span<const uint8_t> rgba, int width, int height,
                                        const std::array<float, 4>& bounds, float minimumContrast = 1.f) {
    if (width < 2 || height < 2 || rgba.size() != size_t(width) * height * 4) return {};
    const auto sample = [&](float x, float y) {
        x = std::clamp(x - 0.5f, 0.f, float(width - 1));
        y = std::clamp(y - 0.5f, 0.f, float(height - 1));
        const int ix = int(x), iy = int(y), nx = std::min(ix + 1, width - 1), ny = std::min(iy + 1, height - 1);
        std::array<float, 3> color{};
        for (int c = 0; c < 3; ++c) {
            const float top = std::lerp(float(rgba[(iy * width + ix) * 4 + c]), float(rgba[(iy * width + nx) * 4 + c]), x - ix);
            const float bottom = std::lerp(float(rgba[(ny * width + ix) * 4 + c]), float(rgba[(ny * width + nx) * 4 + c]), x - ix);
            color[c] = std::lerp(top, bottom, y - iy);
        }
        return color;
    };
    const float extent = std::min(width, height);
    return fitSampledCorners(sample, width, height, bounds, minimumContrast, {extent, extent, extent, extent});
}
}

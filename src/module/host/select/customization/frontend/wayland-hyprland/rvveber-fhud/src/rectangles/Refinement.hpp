#pragma once

#include "Corners.hpp"
#include "Rectangles.hpp"
#include <map>

namespace Fhud {
inline constexpr float ShadowReach = 12.f;
// Native texels around confirmed candidates share one bounded GPU readback.
struct GeometryAtlas {
    static constexpr int Tile = 64, Size = 1024, Columns = Size / Tile, Capacity = Columns * Columns;
    int width, height;
    std::map<std::pair<int, int>, int> tiles;
    std::vector<uint8_t> pixels;

    bool request(float left, float top, float right, float bottom) {
        const int x0 = std::clamp(int(std::floor(left)), 0, width - 1) / Tile;
        const int y0 = std::clamp(int(std::floor(top)), 0, height - 1) / Tile;
        const int x1 = std::clamp(int(std::ceil(right)), 0, width - 1) / Tile;
        const int y1 = std::clamp(int(std::ceil(bottom)), 0, height - 1) / Tile;
        int missing = 0;
        for (int y = y0; y <= y1; ++y)
            for (int x = x0; x <= x1; ++x) missing += !tiles.contains({x, y});
        if (tiles.size() + missing > Capacity) return false;
        for (int y = y0; y <= y1; ++y)
            for (int x = x0; x <= x1; ++x)
                if (!tiles.contains({x, y})) tiles.emplace(std::pair{x, y}, int(tiles.size()));
        return true;
    }

    std::array<float, 3> sample(float x, float y) const {
        x = std::clamp(x - 0.5f, 0.f, float(width - 1));
        y = std::clamp(y - 0.5f, 0.f, float(height - 1));
        const auto pixel = [&](int px, int py, int c) -> float {
            px = std::min(px, width - 1); py = std::min(py, height - 1);
            const auto it = tiles.find({px / Tile, py / Tile});
            if (it == tiles.end()) return 0.f;
            const int ax = it->second % Columns * Tile + px % Tile;
            const int ay = it->second / Columns * Tile + py % Tile;
            return pixels[(ay * Size + ax) * 4 + c];
        };
        std::array<float, 3> result{};
        for (int c = 0; c < 3; ++c)
            result[c] = std::lerp(std::lerp(pixel(int(x), int(y), c), pixel(int(x) + 1, int(y), c), x - int(x)),
                                  std::lerp(pixel(int(x), int(y) + 1, c), pixel(int(x) + 1, int(y) + 1, c), x - int(x)), y - int(y));
        return result;
    }
};


struct GeometryRefinement {
    std::array<bool, 4> edges{}; // Left, top, right, bottom.
    std::array<float, 4> radii{};
};

inline GeometryRefinement requestGeometry(GeometryAtlas& atlas, const Rectangle& box, int reduction,
                                           const std::array<float, 4>& coarseRadii) {
    GeometryRefinement plan;
    const float radius = reduction + 1.f;
    const std::array<float, 4> bounds{box[0] * atlas.width, box[1] * atlas.height,
                                    box[2] * atlas.width, box[3] * atlas.height};
    for (int side = 0; side < 4; ++side) {
        const bool vertical = side % 2 == 0;
        const int axis = vertical ? 1 : 0;
        const float start = std::lerp(bounds[axis], bounds[axis + 2], 0.25f);
        const float end = std::lerp(bounds[axis], bounds[axis + 2], 0.75f);
        const float reach = ShadowReach;
        const float low = bounds[side] - radius - 2 - (side >= 2 ? reach : 0);
        const float high = bounds[side] + radius + 2 + (side < 2 ? reach : 0);
        plan.edges[side] = vertical ? atlas.request(low, start - 2, high, end + 2)
                                    : atlas.request(start - 2, low, end + 2, high);
    }
    const float extent = std::min(bounds[2] - bounds[0], bounds[3] - bounds[1]);
    for (int corner = 0; corner < 4; ++corner) {
        const bool left = corner == 0 || corner == 3, top = corner < 2;
        if (!plan.edges[left ? 0 : 2] || !plan.edges[top ? 1 : 3]) continue;
        const float limit = std::min(extent, std::max(32.f, coarseRadii[corner] * 1.3f + 4.f));
        const float x = bounds[left ? 0 : 2], y = bounds[top ? 1 : 3], margin = radius + 2 + ShadowReach;
        if (atlas.request(x - (left ? margin : limit + margin), y - (top ? margin : limit + margin),
                          x + (left ? limit + margin : margin), y + (top ? limit + margin : margin)))
            plan.radii[corner] = limit;
    }
    return plan;
}

template<class Sample>
inline std::array<bool, 4> refineBounds(const Sample& sample, int width, int height, Rectangle& box,
                                       int reduction, const std::array<bool, 4>& available,
                                       std::span<const Rectangle> parents = {}) {
    const std::array<float, 4> bounds{box[0] * width, box[1] * height, box[2] * width, box[3] * height};
    auto refined = bounds;
    bool shadowAdjusted = false;
    std::array<bool, 4> confirmed{};
    for (int side = 0; side < 4; ++side) {
        if (!available[side]) continue;
        const bool vertical = side % 2 == 0;
        const int axis = vertical ? 1 : 0;
        float low = bounds[side] - reduction - 1.f, high = bounds[side] + reduction + 1.f;
        for (const auto& parent : parents) {
            if ((box[2] - box[0]) * (box[3] - box[1]) > (parent[2] - parent[0]) * (parent[3] - parent[1]) * 0.8f) continue;
            if (parent[0] > box[0] || parent[1] > box[1] || parent[2] < box[2] || parent[3] < box[3]) continue;
            const float boundary = parent[side] * (vertical ? width : height);
            const float inset = side < 2 ? bounds[side] - boundary : boundary - bounds[side];
            if (inset <= 0.5f) continue;
            if (side < 2) low = std::max(low, boundary + 1.5f);
            else high = std::min(high, boundary - 1.5f);
        }
        struct Edge { float position, strength, score; std::array<float, 3> direction; };
        std::vector<Edge> peaks;
        const float reach = ShadowReach;
        const float extendedLow = low - (side >= 2 ? reach : 0), extendedHigh = high + (side < 2 ? reach : 0);
        float best = 0.f, bestStrength = 0.f;
        std::array<float, 3> bestDirection{};
        for (float position = std::ceil(extendedLow * 4.f) / 4.f; position <= extendedHigh; position += 0.25f) {
            std::array<float, 32> strength{};
            std::array<float, 3> sum{};
            float total = 0.f;
            for (int i = 0; i < 32; ++i) {
                const float along = std::lerp(bounds[axis], bounds[axis + 2], 0.25f + 0.5f * (i + 0.5f) / 32.f);
                const auto a = sample(vertical ? position - 0.5f : along, vertical ? along : position - 0.5f);
                const auto b = sample(vertical ? position + 0.5f : along, vertical ? along : position + 0.5f);
                for (int c = 0; c < 3; ++c) {
                    const float delta = b[c] - a[c];
                    sum[c] += delta;
                    total += std::abs(delta);
                    strength[i] = std::max(strength[i], std::abs(delta));
                }
            }
            std::sort(strength.begin(), strength.end());
            const float coherent = std::abs(sum[0]) + std::abs(sum[1]) + std::abs(sum[2]);
            if (strength[8] < 1.f || coherent < total * 0.75f) continue;
            const float displacement = position - bounds[side];
            const float score = strength[8] / (1.f + 0.015f * displacement * displacement);
            peaks.push_back({position, strength[8], score, sum});
        }
        for (size_t i = 0; i < peaks.size(); ++i) {
            const auto& peak = peaks[i];
            if (peak.position < low || peak.position > high) continue;
            if (i > 0 && peak.position - peaks[i - 1].position < 0.3f && peak.strength < peaks[i - 1].strength) continue;
            if (i + 1 < peaks.size() && peaks[i + 1].position - peak.position < 0.3f && peak.strength < peaks[i + 1].strength) continue;
            const float score = peak.score;
            if (score > best) {
                best = score; bestStrength = peak.strength; bestDirection = peak.direction;
                refined[side] = peak.position; confirmed[side] = true;
            }
        }
        // Shadow recovery requires a distributed weak transition before
        // accepting a sharper inward boundary.
        bool diffuse = false;
        for (const auto& peak : peaks) {
            float agreement = 0.f;
            for (int c = 0; c < 3; ++c) agreement += peak.direction[c] * bestDirection[c];
            diffuse |= agreement > 0.f && peak.strength <= bestStrength * 2.f &&
                       std::abs(peak.position - refined[side]) > 1.5f && std::abs(peak.position - refined[side]) <= 4.f;
        }
        const float shadowPosition = refined[side];
        float sharpest = bestStrength;
        for (const auto& peak : peaks) {
            float agreement = 0.f;
            for (int c = 0; c < 3; ++c) agreement += peak.direction[c] * bestDirection[c];
            const float inward = (peak.position - shadowPosition) * (side < 2 ? 1.f : -1.f);
            if (diffuse && confirmed[side] && inward > 0.f && inward <= ShadowReach &&
                peak.strength >= std::max(4.f, bestStrength * 4.f) && agreement < 0.f && peak.strength > sharpest) {
                sharpest = peak.strength; refined[side] = peak.position; shadowAdjusted = true;
            }
        }
    }
    if (refined[2] <= refined[0] || refined[3] <= refined[1]) { box = {}; return {}; }
    // Recovering one surface edge must not attach its opposite side to a neighbor.
    std::array<float, 4> polarity{};
    for (int side = 0; side < 4; ++side) {
        if (!confirmed[side]) continue;
        const bool vertical = side % 2 == 0;
        const int axis = vertical ? 1 : 0;
        for (int i = 0; i < 16; ++i) {
            const float along = std::lerp(bounds[axis], bounds[axis + 2], 0.25f + 0.5f * (i + 0.5f) / 16.f);
            const auto a = sample(vertical ? refined[side] - 1.5f : along, vertical ? along : refined[side] - 1.5f);
            const auto b = sample(vertical ? refined[side] + 1.5f : along, vertical ? along : refined[side] + 1.5f);
            for (int c = 0; c < 3; ++c) polarity[side] += b[c] - a[c];
        }
    }
    if (shadowAdjusted && (polarity[0] * polarity[2] > 0.f || polarity[1] * polarity[3] > 0.f)) { box = {}; return {}; }
    box = {refined[0] / width, refined[1] / height, refined[2] / width, refined[3] / height};
    return confirmed;
}

inline std::vector<std::array<float, 4>> refineGeometry(const GeometryAtlas& atlas, std::vector<Rectangle>& boxes,
                                                       std::span<GeometryRefinement> plans, int reduction) {
    const auto sample = [&](float x, float y) { return atlas.sample(x, y); };
    std::vector<std::array<bool, 4>> supported;
    std::vector<std::array<float, 4>> radii;
    for (size_t i = 0; i < boxes.size(); ++i) {
        const auto confirmed = refineBounds(sample, atlas.width, atlas.height, boxes[i], reduction, plans[i].edges,
                                             std::span<const Rectangle>(boxes).first(i));
        supported.push_back(confirmed);
        for (int corner = 0; corner < 4; ++corner)
            if (!confirmed[corner == 0 || corner == 3 ? 0 : 2] || !confirmed[corner < 2 ? 1 : 3])
                plans[i].radii[corner] = 0.f;
        const auto corners = fitSampledCorners(sample, atlas.width, atlas.height, boxes[i], 1.f, plans[i].radii);
        std::array<float, 4> values{};
        for (size_t c = 0; c < values.size(); ++c) values[c] = corners[c].radius;
        radii.push_back(values);
    }
    // Separate coarse contours can converge onto the same native surface.
    for (size_t i = boxes.size(); i-- > 0;) {
        const auto& box = boxes[i];
        bool remove = box[2] <= box[0] || box[3] <= box[1];
        for (size_t j = 0; j < boxes.size() && !remove; ++j) {
            if (i == j) continue;
            const auto& other = boxes[j];
            int same = 0, unsupported = 0;
            for (int side = 0; side < 4; ++side) {
                const float distance = std::abs(box[side] - other[side]) * (side % 2 ? atlas.height : atlas.width);
                same += distance <= 1.01f;
                unsupported += distance > 1.01f && distance <= ShadowReach && !supported[i][side];
            }
            const bool inside = box[0] >= other[0] && box[1] >= other[1] && box[2] <= other[2] && box[3] <= other[3];
            const bool similar = inside && (box[2] - box[0]) * (box[3] - box[1]) >=
                                            (other[2] - other[0]) * (other[3] - other[1]) * 0.75f;
            const auto complete = [](const auto& sides) { return std::all_of(sides.begin(), sides.end(), [](bool side) { return side; }); };
            remove = (same == 4 && j < i) || (complete(supported[j]) &&
                     ((same == 3 && unsupported == 1) || (similar && !complete(supported[i]))));
        }
        if (remove) {
            boxes.erase(boxes.begin() + i);
            supported.erase(supported.begin() + i);
            radii.erase(radii.begin() + i);
        }
    }
    return radii;
}
}

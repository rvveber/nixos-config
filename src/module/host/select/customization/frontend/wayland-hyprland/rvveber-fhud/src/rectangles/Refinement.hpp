#pragma once

#include "Corners.hpp"
#include "Rectangles.hpp"
#include <map>

namespace Fhud {
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
        plan.edges[side] = vertical
            ? atlas.request(bounds[side] - radius - 2, start - 2, bounds[side] + radius + 2, end + 2)
            : atlas.request(start - 2, bounds[side] - radius - 2, end + 2, bounds[side] + radius + 2);
    }
    const float extent = std::min(bounds[2] - bounds[0], bounds[3] - bounds[1]);
    for (int corner = 0; corner < 4; ++corner) {
        const bool left = corner == 0 || corner == 3, top = corner < 2;
        if (!plan.edges[left ? 0 : 2] || !plan.edges[top ? 1 : 3]) continue;
        const float limit = std::min(extent, std::max(32.f, coarseRadii[corner] * 1.3f + 4.f));
        const float x = bounds[left ? 0 : 2], y = bounds[top ? 1 : 3], margin = radius + 2;
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
    std::array<bool, 4> confirmed{};
    for (int side = 0; side < 4; ++side) {
        if (!available[side]) continue;
        const bool vertical = side % 2 == 0;
        const int axis = vertical ? 1 : 0;
        float low = bounds[side] - reduction - 1.f, high = bounds[side] + reduction + 1.f;
        for (const auto& parent : parents) {
            if (parent[0] > box[0] || parent[1] > box[1] || parent[2] < box[2] || parent[3] < box[3]) continue;
            const float boundary = parent[side] * (vertical ? width : height);
            const float inset = side < 2 ? bounds[side] - boundary : boundary - bounds[side];
            if (inset <= 0.5f) continue;
            if (side < 2) low = std::max(low, boundary + 1.5f);
            else high = std::min(high, boundary - 1.5f);
        }
        float best = 0.f;
        for (float position = std::ceil(low * 4.f) / 4.f; position <= high; position += 0.25f) {
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
            if (score > best) { best = score; refined[side] = position; confirmed[side] = true; }
        }
    }
    if (refined[2] <= refined[0] || refined[3] <= refined[1]) return {};
    box = {refined[0] / width, refined[1] / height, refined[2] / width, refined[3] / height};
    return confirmed;
}
}

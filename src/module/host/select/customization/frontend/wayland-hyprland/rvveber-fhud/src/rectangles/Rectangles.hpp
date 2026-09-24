#pragma once

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <span>
#include <vector>

namespace Fhud {
using Rectangle = std::array<float, 4>;
inline constexpr int MaxRectangles = 64;

// Coordinates are normalized to the source texture, independent of monitor scale.
inline std::vector<Rectangle> detectRectangles(std::span<const uint8_t> rgba, int width, int height) {
    if (width < 16 || height < 16 || rgba.size() != size_t(width) * height * 4)
        return {};

    const auto difference = [&](int a, int b) {
        int delta = 0;
        for (int c = 0; c < 3; ++c)
            delta = std::max(delta, std::abs(int(rgba[a * 4 + c]) - int(rgba[b * 4 + c])));
        return delta;
    };
    std::vector<uint8_t> horizontal(width * height), vertical(width * height);
    for (int y = 2; y < height - 2; ++y) {
        for (int x = 2; x < width - 2; ++x) {
            const int p = y * width + x;
            for (int axis = 0; axis < 2; ++axis) {
                const int across = axis ? 1 : width;
                const int along = axis ? width : 1;
                const int a = p - across, b = p;
                const int contrast = difference(a, b);
                const int calm = std::min(std::max(difference(a, a - along), difference(a, a + along)),
                                          std::max(difference(b, b - along), difference(b, b + along)));
                // An image boundary can have a quiet background on only one side.
                (axis ? vertical : horizontal)[p] = contrast >= 12 && calm <= contrast / 2 + 3;
            }
        }
    }

    struct Line { int position, start, end, support; };
    const auto lines = [&](const std::vector<uint8_t>& edges, bool transpose) {
        std::vector<Line> result;
        const int rows = transpose ? width : height, columns = transpose ? height : width;
        const auto edge = [&](int row, int column) { return edges[transpose ? column * width + row : row * width + column]; };
        for (int row = 2; row < rows - 2; ++row) {
            for (int column = 2; column < columns - 2;) {
                if (!edge(row, column)) { ++column; continue; }
                const int start = column;
                int end = column, support = 0, solid = 0, longest = 0;
                while (column < columns - 2 && column - end <= 6) {
                    if (edge(row, column)) {
                        end = column;
                        ++support;
                        longest = std::max(longest, ++solid);
                    } else solid = 0;
                    ++column;
                }
                if (end - start >= 12 && support >= (end - start + 1) * 0.7 && longest >= 8)
                    result.push_back({row, start, end, support});
            }
        }
        std::stable_sort(result.begin(), result.end(), [](const Line& a, const Line& b) { return a.support > b.support; });
        std::vector<Line> merged;
        for (const auto& line : result) {
            const bool duplicate = std::any_of(merged.begin(), merged.end(), [&](const Line& other) {
                return std::abs(line.position - other.position) <= 2 &&
                    std::min(line.end, other.end) - std::max(line.start, other.start) >=
                        std::min(line.end - line.start, other.end - other.start) * 0.8;
            });
            if (!duplicate) merged.push_back(line);
            if (merged.size() == 128) break;
        }
        std::sort(merged.begin(), merged.end(), [](const Line& a, const Line& b) { return a.position < b.position; });
        return merged;
    };
    const auto hs = lines(horizontal, false), vs = lines(vertical, true);
    const auto support = [&](const std::vector<uint8_t>& edges, int position, int start, int end, bool transpose) {
        const int corner = std::min(12, (end - start) / 5);
        start += corner;
        end -= corner;
        int hits = 0;
        for (int i = start; i <= end; ++i) {
            bool hit = false;
            for (int delta = -1; delta <= 1; ++delta)
                hit |= edges[transpose ? i * width + position + delta : (position + delta) * width + i] != 0;
            hits += hit;
        }
        return float(hits) / std::max(1, end - start + 1);
    };
    struct Candidate { Rectangle bounds; float score, area; };
    std::vector<Candidate> candidates;
    for (size_t t = 0; t < hs.size(); ++t) {
        for (size_t b = t + 1; b < hs.size(); ++b) {
            const auto& top = hs[t];
            const auto& bottom = hs[b];
            const int h = bottom.position - top.position;
            if (h < 12) continue;
            const int start = std::min(top.start, bottom.start), end = std::max(top.end, bottom.end);
            const int corner = std::min(16, std::min(h, end - start) / 4);
            if (std::abs(top.start - bottom.start) > corner + 6 || std::abs(top.end - bottom.end) > corner + 6)
                continue;
            for (const auto& left : vs) {
                if (std::abs(left.position - start) > corner + 3 || left.start > top.position + corner + 3 || left.end < bottom.position - corner - 3)
                    continue;
                for (const auto& right : vs) {
                    if (std::abs(right.position - end) > corner + 3 || right.start > top.position + corner + 3 || right.end < bottom.position - corner - 3 || right.position - left.position < 12)
                        continue;
                    const float score = std::min({
                        support(horizontal, top.position, left.position, right.position, false),
                        support(horizontal, bottom.position, left.position, right.position, false),
                        support(vertical, left.position, top.position, bottom.position, true),
                        support(vertical, right.position, top.position, bottom.position, true)});
                    if (score < 0.7f) continue;
                    candidates.push_back({{float(left.position) / width, float(top.position) / height,
                                           float(right.position) / width, float(bottom.position) / height},
                                          score, float(right.position - left.position) * h});
                }
            }
        }
    }
    std::stable_sort(candidates.begin(), candidates.end(), [](const Candidate& a, const Candidate& b) {
        return a.area != b.area ? a.area > b.area : a.score > b.score;
    });
    std::vector<Rectangle> result;
    const auto area = [](const Rectangle& r) { return (r[2] - r[0]) * (r[3] - r[1]); };
    for (const auto& candidate : candidates) {
        const auto& box = candidate.bounds;
        const bool duplicate = std::any_of(result.begin(), result.end(), [&](const Rectangle& other) {
            const float intersection = std::max(0.f, std::min(box[2], other[2]) - std::max(box[0], other[0])) *
                                       std::max(0.f, std::min(box[3], other[3]) - std::max(box[1], other[1]));
            const bool sameRows = std::abs(box[1] - other[1]) * height <= 2 && std::abs(box[3] - other[3]) * height <= 2;
            const bool sameColumns = std::abs(box[0] - other[0]) * width <= 2 && std::abs(box[2] - other[2]) * width <= 2;
            // Text strokes can propose a narrower box sharing both outer sides.
            return intersection / (area(box) + area(other) - intersection) > 0.85f ||
                   (intersection >= area(box) * 0.98f && (sameRows || sameColumns));
        });
        if (!duplicate) result.push_back(box);
        if (result.size() == MaxRectangles) break;
    }
    // Smaller nested controls receive their own color on top of their enclosing panel.
    std::sort(result.begin(), result.end(), [&](const Rectangle& a, const Rectangle& b) { return area(a) > area(b); });
    return result;
}
}

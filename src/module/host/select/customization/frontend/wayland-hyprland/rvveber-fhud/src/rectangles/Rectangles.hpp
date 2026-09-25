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
inline std::vector<Rectangle> detectRectangles(std::span<const uint8_t> rgba, int width, int height, int weakContrast = 3) {
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
                const int variationA = std::max(difference(a, a - along), difference(a, a + along));
                const int variationB = std::max(difference(b, b - along), difference(b, b + along));
                const int calm = std::min(variationA, variationB);
                // A surface step may vary on one side; a thin ridge needs a stable stroke.
                const bool coherent = std::max(variationA, variationB) <= contrast / 8 + 2 ||
                    difference(a - across, b + across) >= weakContrast;
                const bool strong = coherent && contrast >= 12 && calm <= contrast / 2 + 3;
                const bool weak = coherent && contrast >= weakContrast && calm <= 1 &&
                    contrast > difference(a, a - across) && contrast >= difference(b, b + across);
                (axis ? vertical : horizontal)[p] = strong ? 2 : weak ? 1 : 0;
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
                int end = column, support = 0, strong = 0, solid = 0, longest = 0;
                while (column < columns - 2 && column - end <= 6) {
                    if (edge(row, column)) {
                        end = column;
                        ++support;
                        strong += edge(row, column) == 2;
                        longest = std::max(longest, ++solid);
                    } else solid = 0;
                    ++column;
                }
                const int minimum = strong ? 24 : 48;
                if (end - start >= minimum && support >= (end - start + 1) * 0.9 &&
                    longest >= std::max(minimum / 2.f, (end - start - 5) * 0.5f))
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
    struct Candidate { Rectangle bounds; float evidence, score, area; };
    std::vector<Candidate> candidates;
    const auto infer = [&](const std::vector<Line>& anchors, const std::vector<uint8_t>& edges, bool transpose) {
        const int limit = transpose ? height : width;
        struct Connector { int position; float confidence; };
        for (size_t first = 0; first < anchors.size(); ++first) {
            for (size_t second = first + 1; second < anchors.size(); ++second) {
                const auto& a = anchors[first];
                const auto& b = anchors[second];
                const int separation = b.position - a.position;
                const int shorter = std::min(a.end - a.start, b.end - b.start);
                const int longer = std::max(a.end - a.start, b.end - b.start);
                if (separation < 12 || shorter < longer * 0.75f) continue;
                const int reach = std::min(64, separation / 2 + 2);
                const int alignment = std::min(reach, shorter / 4 + 2);
                if (std::abs(a.start - b.start) > alignment || std::abs(a.end - b.end) > alignment) continue;

                // Short perpendicular evidence is meaningful inside these predicted end regions.
                // Require straight evidence away from corner shoulders; infer the intersections.
                const int inset = std::max(2, separation / 5);
                const auto connector = [&](int endpoint, int outward) {
                    const auto confidence = [&](int position) {
                        if (position < 2 || position >= limit - 2) return 0.f;
                        const auto edge = [&](int i) { return edges[transpose ? position * width + i : i * width + position]; };
                        int start = -1, end = -1, hits = 0, run = 0, longest = 0, gap = 0, largestGap = 0;
                        for (int i = a.position + 2; i <= b.position - 2; ++i) {
                            if (edge(i)) {
                                if (start < 0) start = i;
                                end = i;
                                largestGap = std::max(largestGap, gap);
                                gap = 0;
                                ++hits;
                                if (i >= a.position + inset && i <= b.position - inset)
                                    longest = std::max(longest, ++run);
                                else run = 0;
                            } else {
                                run = 0;
                                if (start >= 0) ++gap;
                            }
                        }
                        const int span = end - start + 1;
                        const float coverage = span >= 24 ? 0.9f : 0.7f;
                        const float sustained = span >= 24 ? std::max(4.f, (span - 6) * 0.5f) : 4.f;
                        if (largestGap > 6 || longest < sustained || hits < 4 || hits < span * coverage) return 0.f;
                        // Each connector end must fit the corner region predicted by its anchor.
                        // Outward extension allows a rounded corner; an inward cut needs a junction.
                        const auto cornerSupport = [&](const Line& anchor, int tip, int direction) {
                            const int anchorEnd = outward < 0 ? anchor.start : anchor.end;
                            const int extension = std::max(0, (position - anchorEnd) * outward);
                            const int gap = std::abs(tip - anchor.position);
                            const int tolerance = std::max(8, extension / 2);
                            if (gap > extension + tolerance) return false;
                            const int overshoot = (anchorEnd - position) * outward;
                            if (overshoot > 1) {
                                const int i = anchor.position - direction;
                                const int junction = transpose ? position * width + i : i * width + position;
                                if (gap > 2 || difference(junction, junction - (transpose ? width : 1)) < weakContrast) return false;
                            }
                            // Rounding joins two ending segments; a passing side needs a real junction.
                            if (extension > 1 && gap <= 2) {
                                int run = 0;
                                for (int distance = 3; distance <= 8; ++distance) {
                                    const int i = anchor.position + distance * direction;
                                    if (i < 2 || i >= (transpose ? width : height) - 2) break;
                                    if (edge(i)) {
                                        if (++run >= 4) return false;
                                    } else run = 0;
                                }
                            }
                            return true;
                        };
                        if (!cornerSupport(a, start, -1) || !cornerSupport(b, end, 1)) return 0.f;
                        return float(hits) / (separation - 3);
                    };
                    // Maximize supported coverage between the connections; proximity only breaks ties.
                    Connector best{-1, 0.f};
                    for (int distance = 0; distance <= reach; ++distance) {
                        const int position = endpoint + distance * outward;
                        const float score = confidence(position);
                        if (score > best.confidence) best = Connector{position, score};
                    }
                    for (int distance = 1; distance <= reach; ++distance) {
                        const int position = endpoint - distance * outward;
                        const float score = confidence(position);
                        if (score > best.confidence) best = Connector{position, score};
                    }
                    return best;
                };
                const auto start = connector(std::min(a.start, b.start), -1);
                if (start.position < 0) continue;
                const auto end = connector(std::max(a.end, b.end), 1);
                if (end.position - start.position < std::max(12.f, shorter * 0.7f)) continue;
                const float score = std::min({start.confidence, end.confidence,
                    float(a.support) / (a.end - a.start + 1), float(b.support) / (b.end - b.start + 1)});
                const Rectangle bounds = transpose
                    ? Rectangle{float(a.position) / width, float(start.position) / height,
                                float(b.position) / width, float(end.position) / height}
                    : Rectangle{float(start.position) / width, float(a.position) / height,
                                float(end.position) / width, float(b.position) / height};
                const int anchorStart = std::max(a.start, start.position), anchorEnd = std::min(a.end, end.position);
                const int otherStart = std::max(b.start, start.position), otherEnd = std::min(b.end, end.position);
                const float evidence = float(a.support) * std::max(0, anchorEnd - anchorStart + 1) / (a.end - a.start + 1) +
                    float(b.support) * std::max(0, otherEnd - otherStart + 1) / (b.end - b.start + 1) +
                    (separation - 3) * (start.confidence + end.confidence);
                candidates.push_back({bounds, evidence, score, float(end.position - start.position) * separation});
            }
        }
    };
    infer(hs, vertical, false);
    infer(vs, horizontal, true);
    std::stable_sort(candidates.begin(), candidates.end(), [](const Candidate& a, const Candidate& b) {
        if (a.evidence != b.evidence) return a.evidence > b.evidence;
        return a.score != b.score ? a.score > b.score : a.area > b.area;
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

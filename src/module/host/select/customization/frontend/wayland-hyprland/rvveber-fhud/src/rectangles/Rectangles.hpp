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
    enum : uint8_t { NoEdge, FaintEdge, WeakEdge, StrongEdge };
    std::vector<uint8_t> horizontal(width * height), vertical(width * height);
    for (int y = 2; y < height - 2; ++y) {
        for (int x = 2; x < width - 2; ++x) {
            const int p = y * width + x;
            for (int axis = 0; axis < 2; ++axis) {
                const int across = axis ? 1 : width;
                const int along = axis ? width : 1;
                const int a = p - across, b = p;
                const int contrast = difference(a, b);
                if (contrast == 0) continue;
                const int variationA = std::max(difference(a, a - along), difference(a, a + along));
                const int variationB = std::max(difference(b, b - along), difference(b, b + along));
                const int calm = std::min(variationA, variationB);
                // A surface step may vary on one side; a thin ridge needs a stable stroke.
                const bool coherent = std::max(variationA, variationB) <= contrast / 8 + 2 ||
                    difference(a - across, b + across) >= weakContrast;
                const bool strong = coherent && contrast >= 12 && calm <= contrast / 2 + 3;
                const bool peak = contrast > std::min(difference(a, a - across), difference(b, b + across));
                const int interiorCalm = calm <= 1 ? calm : std::min({calm,
                    std::max(difference(a - across, a - across - along), difference(a - across, a - across + along)),
                    std::max(difference(b + across, b + across - along), difference(b + across, b + across + along))});
                const bool weak = coherent && contrast >= weakContrast && interiorCalm <= 1 && peak;
                const bool faint = std::max(variationA, variationB) <= 1 && peak;
                (axis ? vertical : horizontal)[p] = strong ? StrongEdge : weak ? WeakEdge : faint ? FaintEdge : NoEdge;
            }
        }
    }

    struct Line { int position, start, end, support, centered, polarity; bool section = false; };
    const auto lines = [&](const std::vector<uint8_t>& edges, bool transpose) {
        std::vector<Line> result;
        const int rows = transpose ? width : height, columns = transpose ? height : width;
        const auto edge = [&](int row, int column) {
            const int p = transpose ? column * width + row : row * width + column;
            const int across = transpose ? 1 : width;
            const auto value = std::max({edges[p - across], edges[p], edges[p + across]});
            return value >= WeakEdge ? value : uint8_t(NoEdge);
        };
        for (int row = 2; row < rows - 2; ++row) {
            for (int column = 2; column < columns - 2;) {
                if (!edge(row, column)) { ++column; continue; }
                const int start = column;
                int end = column, support = 0, strong = 0, solid = 0, longest = 0, centered = 0, polarity = 0;
                while (column < columns - 2 && column - end <= 6) {
                    if (edge(row, column)) {
                        end = column;
                        ++support;
                        const int p = transpose ? column * width + row : row * width + column;
                        const int across = transpose ? 1 : width;
                        centered += edges[p] >= WeakEdge;
                        for (int c = 0; c < 3; ++c) polarity += int(rgba[p * 4 + c]) - int(rgba[(p - across) * 4 + c]);
                        strong += edge(row, column) == StrongEdge;
                        longest = std::max(longest, ++solid);
                    } else solid = 0;
                    ++column;
                }
                const int minimum = strong ? 24 : 48;
                if (end - start >= minimum && support >= (end - start + 1) * 0.9 &&
                    longest >= std::max(minimum / 2.f, (end - start - 5) * 0.5f)) {
                    int first = start, last = end, run = 0;
                    for (int i = start; i <= end; ++i) {
                        const int p = transpose ? i * width + row : row * width + i;
                        run = edges[p] >= WeakEdge ? run + 1 : 0;
                        if (run == 8) { first = i - 7; break; }
                    }
                    run = 0;
                    for (int i = end; i >= first; --i) {
                        const int p = transpose ? i * width + row : row * width + i;
                        run = edges[p] >= WeakEdge ? run + 1 : 0;
                        if (run == 8) { last = i + 7; break; }
                    }
                    const int length = last - first + 1;
                    result.push_back({row, first, last, support * length / (end - start + 1),
                        centered * length / (end - start + 1), (polarity > 0) - (polarity < 0)});
                    // Preserve independently coherent sections of an accepted line.
                    // The full span remains available when only one side is interrupted.
                    std::vector<Line> sections;
                    for (int begin = first; begin <= last;) {
                        while (begin <= last && !edge(row, begin)) ++begin;
                        int finish = begin, cursor = begin, hits = 0, direct = 0, intense = 0, direction = 0;
                        while (cursor <= last && cursor - finish <= 2) {
                            if (edge(row, cursor)) {
                                finish = cursor;
                                ++hits;
                                const int p = transpose ? cursor * width + row : row * width + cursor;
                                const int across = transpose ? 1 : width;
                                direct += edges[p] >= WeakEdge;
                                intense += edge(row, cursor) == StrongEdge;
                                for (int c = 0; c < 3; ++c) direction += int(rgba[p * 4 + c]) - int(rgba[(p - across) * 4 + c]);
                            }
                            ++cursor;
                        }
                        if (finish - begin >= (intense ? 24 : 48) && hits >= (finish - begin + 1) * 0.9f)
                            sections.push_back({row, begin, finish, hits, direct, (direction > 0) - (direction < 0), true});
                        begin = cursor;
                    }
                    if (sections.size() > 1) result.insert(result.end(), sections.begin(), sections.end());
                }
            }
        }
        std::stable_sort(result.begin(), result.end(), [](const Line& a, const Line& b) {
            return a.centered != b.centered ? a.centered > b.centered : a.support > b.support;
        });
        std::vector<Line> merged;
        for (const auto& line : result) {
            const bool duplicate = std::any_of(merged.begin(), merged.end(), [&](const Line& other) {
                return line.polarity * other.polarity >= 0 && std::abs(line.position - other.position) <= 2 &&
                    (!(line.section || other.section) || std::min(line.end - line.start, other.end - other.start) >=
                        std::max(line.end - line.start, other.end - other.start) * 0.75f) &&
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
    struct Candidate { Rectangle bounds; float geometry, evidence, score, area; };
    std::vector<Candidate> candidates;
    const auto infer = [&](const std::vector<Line>& anchors, const std::vector<uint8_t>& edges, bool transpose) {
        const int limit = transpose ? height : width;
        struct Connector { int position; float confidence, corners, reciprocal; };
        const auto& orthogonal = transpose ? hs : vs;
        for (size_t first = 0; first < anchors.size(); ++first) {
            for (size_t second = first + 1; second < anchors.size(); ++second) {
                auto a = anchors[first];
                auto b = anchors[second];
                const int separation = b.position - a.position;
                if (separation < 6) continue;
                const int overlap = std::min(a.end, b.end) - std::max(a.start, b.start);
                const int shorter = std::min(a.end - a.start, b.end - b.start);
                const int longer = std::max(a.end - a.start, b.end - b.start);
                if (shorter < longer * 0.75f) {
                    if (overlap < shorter * 0.95f) continue;
                    auto& line = a.end - a.start > b.end - b.start ? a : b;
                    line.support = line.support * (overlap + 1) / (line.end - line.start + 1);
                    line.start = std::max(a.start, b.start);
                    line.end = std::min(a.end, b.end);
                    int polarity = 0;
                    for (int i = line.start; i <= line.end; ++i) {
                        const int p = transpose ? i * width + line.position : line.position * width + i;
                        const int across = transpose ? 1 : width;
                        for (int c = 0; c < 3; ++c) polarity += int(rgba[p * 4 + c]) - int(rgba[(p - across) * 4 + c]);
                    }
                    line.polarity = (polarity > 0) - (polarity < 0);
                }
                if (a.polarity * b.polarity > 0) continue;
                int sharedGap = 0;
                bool disconnected = false;
                for (int i = std::max(a.start, b.start); i <= std::min(a.end, b.end); ++i) {
                    const auto& mask = transpose ? vertical : horizontal;
                    const int across = transpose ? 1 : width;
                    const auto supported = [&](int position) {
                        const int p = transpose ? i * width + position : position * width + i;
                        return std::max({mask[p - across], mask[p], mask[p + across]}) >= WeakEdge;
                    };
                    sharedGap = supported(a.position) || supported(b.position) ? 0 : sharedGap + 1;
                    if (sharedGap >= 2) { disconnected = true; break; }
                }
                if (disconnected) continue;
                const int reach = std::min(64, separation / 2 + 2);
                const int alignment = std::min(reach, shorter / 4 + 2);
                if (std::abs(a.start - b.start) > alignment || std::abs(a.end - b.end) > alignment) continue;

                // Short perpendicular evidence is meaningful inside these predicted end regions.
                // Require straight evidence away from corner shoulders; infer the intersections.
                const int margin = separation < 12 ? 1 : 2;
                const int minimumSide = separation < 12 ? 2 : 4;
                const int inset = std::max(margin, separation / 5);
                const auto connector = [&](int endpoint, int outward) {
                    float corners = 1.f;
                    const auto confidence = [&](int position) {
                        corners = 1.f;
                        if (position < 2 || position >= limit - 2) return 0.f;
                        const auto edge = [&](int i) {
                            const int p = transpose ? position * width + i : i * width + position;
                            const int across = transpose ? width : 1;
                            return std::max({edges[p - across], edges[p], edges[p + across]});
                        };
                        int start = -1, end = -1;
                        int hits = 0, centered = 0, faint = 0, run = 0, longest = 0, gap = 0, largestGap = 0;
                        for (int i = a.position + margin; i <= b.position - margin; ++i) {
                            if (edge(i)) {
                                if (start < 0) start = i;
                                end = i;
                                largestGap = std::max(largestGap, gap);
                                gap = 0;
                                ++hits;
                                const int p = transpose ? position * width + i : i * width + position;
                                centered += edges[p] != NoEdge;
                                faint += edge(i) == FaintEdge;
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
                        const float sustained = span >= 24 ? std::max(4.f, (span - 6) * 0.5f) : float(minimumSide);
                        if (largestGap > 6 || longest < sustained || hits < minimumSide || hits < span * coverage || centered < (separation < 12 ? 1 : (hits + 1) / 2)) return 0.f;
                        // Subthreshold evidence only completes a long side predicted by established anchors.
                        if (faint && (span < 24 || hits < span * 0.95f)) return 0.f;
                        // Each connector end must fit the corner region predicted by its anchor.
                        // Outward extension allows a rounded corner; an inward cut needs a junction.
                        const auto cornerSupport = [&](const Line& anchor, int tip, int direction) {
                            const int anchorEnd = outward < 0 ? anchor.start : anchor.end;
                            const int vertex = anchorEnd + (outward > 0 ? 1 : 0);
                            const int extension = std::max(0, (position - vertex) * outward);
                            const int gap = std::abs(tip - anchor.position);
                            const int tolerance = std::max(8, extension / 2);
                            if (gap > extension + tolerance) return false;
                            const int overshoot = (vertex - position) * outward;
                            if (overshoot > 1) {
                                const int i = anchor.position - direction;
                                const int junction = transpose ? position * width + i : i * width + position;
                                if (gap > 2 || difference(junction, junction - (transpose ? width : 1)) < weakContrast) return false;
                            }
                            const auto cornerPath = [&] {
                                const int origin = anchorEnd - 6 * outward + (outward > 0 ? 1 : 0);
                                const int distance = std::abs(position - origin);
                                const int depthLimit = std::min(extension + tolerance + 4, separation / 2);
                                const auto pixel = [&](int u, int v) { return transpose ? u * width + v : v * width + u; };
                                std::vector<float> connected(distance + 1, -1.f);
                                const auto strength = [&](int p, int across, int polarity) {
                                    int transition = 0;
                                    for (int c = 0; c < 3; ++c) transition += int(rgba[p * 4 + c]) - int(rgba[(p - across) * 4 + c]);
                                    const int direct = difference(p, p - across);
                                    const float weight = direct == 0 ? 0 : std::min(4, std::max(direct, difference(p + across, p - 2 * across) / 2));
                                    return transition * polarity < 0 ? weight * 0.25f : weight;
                                };
                                float best = 0.f;
                                // Keep the confidence of the complete turn, including its straight continuation.
                                for (int depth = 0; depth <= depthLimit; ++depth) {
                                    const int v = anchor.position - depth * direction;
                                    bool any = false;
                                    for (int step = 0; step <= distance; ++step) {
                                        const int u = origin + step * outward;
                                        float reachable = depth == 0 && step == 0 ? 0.f : -1.f;
                                        if (depth > 0 && connected[step] >= 0.f) {
                                            const int p = pixel(u, v - (direction < 0 ? 1 : 0));
                                            const float weight = strength(p, transpose ? width : 1, anchor.polarity * direction * outward);
                                            if (weight) reachable = std::max(reachable, connected[step] + weight);
                                        }
                                        if (step > 0 && connected[step - 1] >= 0.f) {
                                            const int p = pixel(u - (outward > 0 ? 1 : 0), v);
                                            const float weight = strength(p, transpose ? 1 : width, anchor.polarity);
                                            if (weight) reachable = std::max(reachable, connected[step - 1] + weight);
                                        }
                                        connected[step] = reachable;
                                        any |= reachable >= 0.f;
                                    }
                                    if (connected.back() >= 0.f) {
                                        float weight = connected.back();
                                        const int continuation = std::min(4, separation - depth - 2);
                                        for (int step = 1; step <= continuation; ++step) {
                                            const int p = pixel(position, v - step * direction - (direction < 0 ? 1 : 0));
                                            const float value = strength(p, transpose ? width : 1, anchor.polarity * direction * outward);
                                            if (!value) { weight = -1.f; break; }
                                            weight += value;
                                        }
                                        best = std::max(best, weight / (4 * (distance + depth + continuation)));
                                        if (best >= 1.f) return best;
                                    }
                                    if (!any) break;
                                }
                                return best;
                            };
                            const float observed = overshoot <= 1 ? cornerPath() : 0.f;
                            corners = std::min(corners, std::min(1.f, observed / 0.95f));
                            // A passing side needs a junction or a visible turn into the anchor.
                            if (extension > 0 && gap <= 2) {
                                int run = 0;
                                for (int distance = 3; distance <= 8; ++distance) {
                                    const int i = anchor.position + distance * direction;
                                    if (i < 2 || i >= (transpose ? width : height) - 2) break;
                                    if (edge(i)) {
                                        if (++run >= 4) return observed >= 0.75f;
                                    } else run = 0;
                                }
                            }
                            return true;
                        };
                        if (!cornerSupport(a, start, -1) || !cornerSupport(b, end, 1)) return 0.f;
                        return float(hits) / (separation - 2 * margin + 1);
                    };
                    const auto reciprocal = [&](int position) {
                        float best = 0.f;
                        for (const auto& line : orthogonal) {
                            if (std::abs(line.position - position) > 1) continue;
                            const int overlap = std::min(line.end, b.position) - std::max(line.start, a.position);
                            if (overlap < separation * 0.6f) continue;
                            const float extension = std::abs(line.start - a.position) + std::abs(line.end - b.position);
                            const float coverage = std::min(1.f, float(line.support) / separation);
                            best = std::max(best, coverage / (1.f + extension / std::max(4.f, separation * 0.1f)));
                        }
                        return best;
                    };
                    std::vector<Connector> choices;
                    for (int distance = 0; distance <= reach; ++distance) {
                        const int position = endpoint + distance * outward;
                        const float score = confidence(position);
                        if (score > 0.f) choices.push_back({position, score, corners, reciprocal(position)});
                    }
                    for (int distance = 1; distance <= reach; ++distance) {
                        const int position = endpoint - distance * outward;
                        const float score = confidence(position);
                        if (score > 0.f) choices.push_back({position, score, corners, reciprocal(position)});
                    }
                    return choices;
                };
                const auto starts = connector(std::min(a.start, b.start), -1);
                if (starts.empty()) continue;
                const auto ends = connector(std::max(a.end, b.end), 1);
                if (ends.empty()) continue;
                constexpr float symmetryWeight = 0.2f;
                const auto rank = [](const Connector& side) { return side.corners + 0.25f * (side.confidence + side.reciprocal); };
                const float tolerance = std::max(2.f, std::abs(a.start + a.end - b.start - b.end) / 2.f);
                const auto select = [&](const std::vector<Connector>& choices, float expected, float weight) {
                    return *std::max_element(choices.begin(), choices.end(), [&](const Connector& x, const Connector& y) {
                        const auto score = [&](const Connector& side) {
                            const float offset = (side.position - expected) / tolerance;
                            return rank(side) + weight / (1.f + offset * offset);
                        };
                        return score(x) < score(y);
                    });
                };
                auto start = select(starts, 0.f, 0.f);
                auto end = select(ends, 0.f, 0.f);
                // Reflect the better-supported side through the anchors' shared midpoint.
                // Symmetry boosts observed candidates; it never supplies a missing edge.
                const float twiceCenter = (a.start + a.end + b.start + b.end + 2) / 2.f;
                if (rank(start) >= rank(end))
                    end = select(ends, twiceCenter - start.position, symmetryWeight * std::min(std::max(start.corners, start.reciprocal), start.confidence));
                else
                    start = select(starts, twiceCenter - end.position, symmetryWeight * std::min(std::max(end.corners, end.reciprocal), end.confidence));
                if (end.position - start.position < std::max(6.f, shorter * 0.7f)) continue;

                if ((shorter < longer * 0.75f || separation < 12) && std::min(start.corners, end.corners) < 0.75f) continue;
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
                const float offset = (start.position + end.position - twiceCenter) / tolerance;
                const float geometry = std::min(start.corners, end.corners) * (1.f + symmetryWeight / (1.f + offset * offset));
                candidates.push_back({bounds, geometry, evidence, score, float(end.position - start.position) * separation});
            }
        }
    };
    infer(hs, vertical, false);
    infer(vs, horizontal, true);
    std::stable_sort(candidates.begin(), candidates.end(), [](const Candidate& a, const Candidate& b) {
        const auto confidence = [](float geometry) { return geometry < 0.75f ? 0 : int(std::round(geometry * 5)); };
        if (confidence(a.geometry) != confidence(b.geometry)) return confidence(a.geometry) > confidence(b.geometry);
        if (a.evidence != b.evidence) return a.evidence > b.evidence;
        return a.score != b.score ? a.score > b.score : a.area > b.area;
    });
    std::vector<Rectangle> result;
    std::vector<float> geometry;
    const auto area = [](const Rectangle& r) { return (r[2] - r[0]) * (r[3] - r[1]); };
    for (const auto& candidate : candidates) {
        const auto& box = candidate.bounds;
        const bool duplicate = std::any_of(result.begin(), result.end(), [&](const Rectangle& other) {
            const float intersection = std::max(0.f, std::min(box[2], other[2]) - std::max(box[0], other[0])) *
                                       std::max(0.f, std::min(box[3], other[3]) - std::max(box[1], other[1]));
            const float shortSide = std::min({(box[2] - box[0]) * width, (box[3] - box[1]) * height,
                (other[2] - other[0]) * width, (other[3] - other[1]) * height});
            const float tolerance = shortSide < 24 ? 0.5f : 2.01f;
            const bool sameRows = std::abs(box[1] - other[1]) * height < tolerance && std::abs(box[3] - other[3]) * height < tolerance;
            const bool sameColumns = std::abs(box[0] - other[0]) * width < tolerance && std::abs(box[2] - other[2]) * width < tolerance;
            // Text strokes can propose a narrower box sharing both outer sides.
            return intersection / (area(box) + area(other) - intersection) > 0.85f ||
                   (intersection >= std::min(area(box), area(other)) * 0.98f && (sameRows || sameColumns));
        });
        if (!duplicate) {
            result.push_back(box);
            geometry.push_back(candidate.geometry);
        }
        if (result.size() == MaxRectangles) break;
    }
    // A confirmed inset control explains its own edges; avoid combining one of
    // them with the enclosing panel's sides into an additional surface.
    std::vector<bool> composite(result.size());
    const auto contains = [](const Rectangle& outer, const Rectangle& inner) {
        return outer[0] <= inner[0] && outer[1] <= inner[1] && outer[2] >= inner[2] && outer[3] >= inner[3];
    };
    for (size_t i = 0; i < result.size(); ++i) {
        if (geometry[i] >= 1.19f) continue;
        const auto& box = result[i];
        for (size_t p = 0; p < result.size() && !composite[i]; ++p) {
            const auto& parent = result[p];
            if (area(box) >= area(parent) * 0.95f) continue;
            for (int axis = 0; axis < 2 && !composite[i]; ++axis) {
                const int across = axis, along = 1 - axis;
                const float acrossScale = axis ? height : width, alongScale = axis ? width : height;
                const float firstSide = std::abs(box[across] - parent[across]) * acrossScale;
                const float secondSide = std::abs(box[across + 2] - parent[across + 2]) * acrossScale;
                if ((geometry[i] < 0.75f ? std::min(firstSide, secondSide) : std::max(firstSide, secondSide)) > 2.01f) continue;
                for (size_t c = 0; c < result.size(); ++c) {
                    const auto& child = result[c];
                    if (geometry[c] < 1.f || !contains(parent, child) || area(child) >= area(box) * 0.8f) continue;
                    const float childWidth = child[across + 2] - child[across];
                    if (childWidth < (box[across + 2] - box[across]) * 0.75f ||
                        childWidth >= parent[across + 2] - parent[across]) continue;
                    const float distance = std::min({std::abs(box[along] - child[along]),
                        std::abs(box[along] - child[along + 2]), std::abs(box[along + 2] - child[along]),
                        std::abs(box[along + 2] - child[along + 2])}) * alongScale;
                    const float overlap = std::max(0.f, std::min(box[2], parent[2]) - std::max(box[0], parent[0])) *
                        std::max(0.f, std::min(box[3], parent[3]) - std::max(box[1], parent[1]));
                    if (distance <= 1.01f || (geometry[i] < 0.75f && overlap >= area(box) * 0.75f)) {
                        composite[i] = true;
                        break;
                    }
                }
            }
        }
    }
    for (size_t i = result.size(); i-- > 0;)
        if (composite[i]) result.erase(result.begin() + i);
    // Smaller nested controls receive their own color on top of their enclosing panel.
    std::sort(result.begin(), result.end(), [&](const Rectangle& a, const Rectangle& b) { return area(a) > area(b); });
    return result;
}
}

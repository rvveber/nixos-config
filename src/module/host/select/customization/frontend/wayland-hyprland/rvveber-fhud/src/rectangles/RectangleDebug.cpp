#include "RectangleDebug.hpp"
#include <hyprutils/utils/ScopeGuard.hpp>

void FhudRectangleDebug::observe(const SP<CWLSurfaceResource>& surface) {
    if (m_surface == surface) return;
    m_surface = surface;
    m_dirty = true;
    m_commit = surface->m_events.commit.listen([this] { m_dirty = true; });
}

bool FhudRectangleDebug::update(const SP<Render::ITexture>& texture) {
    m_rectangles.clear();
    m_cornerRadii.clear();
    if (!texture || texture->m_type == Render::TEXTURE_EXTERNAL || texture->m_size.x < 16 || texture->m_size.y < 16)
        return false;
    int width = int(texture->m_size.x), height = int(texture->m_size.y);
    int reduction = 1;

    GLint read, draw, renderbuffer, packBuffer, alignment, rowLength, skipRows, skipPixels;
    glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &read);
    glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &draw);
    glGetIntegerv(GL_RENDERBUFFER_BINDING, &renderbuffer);
    glGetIntegerv(GL_PIXEL_PACK_BUFFER_BINDING, &packBuffer);
    glGetIntegerv(GL_PACK_ALIGNMENT, &alignment);
    glGetIntegerv(GL_PACK_ROW_LENGTH, &rowLength);
    glGetIntegerv(GL_PACK_SKIP_ROWS, &skipRows);
    glGetIntegerv(GL_PACK_SKIP_PIXELS, &skipPixels);
    const bool scissor = glIsEnabled(GL_SCISSOR_TEST);
    GLuint framebuffers[2], buffers[2];
    glGenFramebuffers(2, framebuffers);
    glGenRenderbuffers(2, buffers);
    Hyprutils::Utils::CScopeGuard restore([&] {
        glBindFramebuffer(GL_READ_FRAMEBUFFER, read);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, draw);
        glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
        glBindBuffer(GL_PIXEL_PACK_BUFFER, packBuffer);
        glPixelStorei(GL_PACK_ALIGNMENT, alignment);
        glPixelStorei(GL_PACK_ROW_LENGTH, rowLength);
        glPixelStorei(GL_PACK_SKIP_ROWS, skipRows);
        glPixelStorei(GL_PACK_SKIP_PIXELS, skipPixels);
        if (scissor) glEnable(GL_SCISSOR_TEST);
        glDeleteFramebuffers(2, framebuffers);
        glDeleteRenderbuffers(2, buffers);
    });
    glDisable(GL_SCISSOR_TEST);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffers[0]);
    glFramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture->m_texID, 0);
    if (glCheckFramebufferStatus(GL_READ_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) return false;
    int current = 0;
    do {
        const bool halve = std::max(width, height) > 1024;
        const int nextWidth = halve ? width / 2 : width;
        const int nextHeight = halve ? height / 2 : height;
        if (nextWidth < 1 || nextHeight < 1) return false;
        const int next = 1 - current;
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffers[next]);
        glBindRenderbuffer(GL_RENDERBUFFER, buffers[next]);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, nextWidth, nextHeight);
        glFramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, buffers[next]);
        if (glCheckFramebufferStatus(GL_DRAW_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) return false;
        // Exact 2x2 footprints preserve thin-line coverage at every sampling phase.
        // An odd trailing row/column lies within the detector's unused edge margin.
        glBlitFramebuffer(0, 0, nextWidth * (halve ? 2 : 1), nextHeight * (halve ? 2 : 1),
                          0, 0, nextWidth, nextHeight, GL_COLOR_BUFFER_BIT, GL_LINEAR);
        width = nextWidth;
        height = nextHeight;
        if (halve) reduction *= 2;
        current = next;
        glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffers[current]);
    } while (std::max(width, height) > 1024);
    glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
    glPixelStorei(GL_PACK_ALIGNMENT, 1);
    glPixelStorei(GL_PACK_ROW_LENGTH, 0);
    glPixelStorei(GL_PACK_SKIP_ROWS, 0);
    glPixelStorei(GL_PACK_SKIP_PIXELS, 0);
    std::vector<uint8_t> pixels(size_t(width) * height * 4);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels.data());
    m_rectangles = Fhud::detectRectangles(pixels, width, height, std::max(1, 3 / reduction));
    std::vector<std::array<float, 4>> coarseRadii;
    for (auto& box : m_rectangles) {
        const auto corners = Fhud::fitCorners(pixels, width, height, box, std::max(1, 3 / reduction));
        std::array<float, 4> radii{};
        for (size_t i = 0; i < radii.size(); ++i) radii[i] = corners[i].radius * reduction;
        coarseRadii.push_back(radii);
        box[0] *= double(width * reduction) / texture->m_size.x;
        box[2] *= double(width * reduction) / texture->m_size.x;
        box[1] *= double(height * reduction) / texture->m_size.y;
        box[3] *= double(height * reduction) / texture->m_size.y;
    }
    Fhud::GeometryAtlas atlas{int(texture->m_size.x), int(texture->m_size.y), {}, {}};
    std::vector<Fhud::GeometryRefinement> plans;
    for (size_t i = 0; i < m_rectangles.size(); ++i)
        plans.push_back(Fhud::requestGeometry(atlas, m_rectangles[i], reduction, coarseRadii[i]));
    if (!atlas.tiles.empty()) {
        glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffers[0]);
        glFramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture->m_texID, 0);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffers[1]);
        glBindRenderbuffer(GL_RENDERBUFFER, buffers[1]);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, atlas.Size, atlas.Size);
        glFramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, buffers[1]);
        if (glCheckFramebufferStatus(GL_READ_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE ||
            glCheckFramebufferStatus(GL_DRAW_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
            m_rectangles.clear();
            return false;
        }
        for (const auto& [tile, slot] : atlas.tiles) {
            const int x = tile.first * atlas.Tile, y = tile.second * atlas.Tile;
            const int w = std::min(atlas.Tile, atlas.width - x), h = std::min(atlas.Tile, atlas.height - y);
            const int ax = slot % atlas.Columns * atlas.Tile, ay = slot / atlas.Columns * atlas.Tile;
            glBlitFramebuffer(x, y, x + w, y + h, ax, ay, ax + w, ay + h, GL_COLOR_BUFFER_BIT, GL_NEAREST);
        }
        glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffers[1]);
        const int rows = (int(atlas.tiles.size()) + atlas.Columns - 1) / atlas.Columns * atlas.Tile;
        atlas.pixels.resize(size_t(atlas.Size) * rows * 4);
        glReadPixels(0, 0, atlas.Size, rows, GL_RGBA, GL_UNSIGNED_BYTE, atlas.pixels.data());
    }
    const auto sample = [&](float x, float y) { return atlas.sample(x, y); };
    for (size_t i = 0; i < m_rectangles.size(); ++i) {
        auto& box = m_rectangles[i];
        const auto confirmed = Fhud::refineBounds(sample, atlas.width, atlas.height, box, reduction, plans[i].edges,
                                                   std::span<const Fhud::Rectangle>(m_rectangles).first(i));
        for (int corner = 0; corner < 4; ++corner)
            if (!confirmed[corner == 0 || corner == 3 ? 0 : 2] || !confirmed[corner < 2 ? 1 : 3])
                plans[i].radii[corner] = 0.f;
        const auto corners = Fhud::fitSampledCorners(sample, atlas.width, atlas.height, box, 1.f, plans[i].radii);
        std::array<float, 4> radii{};
        for (size_t c = 0; c < radii.size(); ++c) radii[c] = corners[c].radius / texture->m_size.x;
        m_cornerRadii.push_back(radii);
    }
    return true;
}

void FhudRectangleDebug::apply(GLuint program, const std::shared_ptr<FhudRectangleDebug>& cache, const SP<Render::ITexture>& texture) {
    if (cache && cache->m_dirty) {
        cache->update(texture);
        cache->m_dirty = false;
    }
    GLint previous;
    glGetIntegerv(GL_CURRENT_PROGRAM, &previous);
    glUseProgram(program);
    const int count = cache ? cache->m_rectangles.size() : 0;
    glUniform1i(glGetUniformLocation(program, "fhudRectangleCount"), count);
    if (count) {
        glUniform4fv(glGetUniformLocation(program, "fhudRectangleBounds[0]"), count, cache->m_rectangles.front().data());
        glUniform4fv(glGetUniformLocation(program, "fhudCornerRadii[0]"), count, cache->m_cornerRadii.front().data());
    }
    glUseProgram(previous);
}

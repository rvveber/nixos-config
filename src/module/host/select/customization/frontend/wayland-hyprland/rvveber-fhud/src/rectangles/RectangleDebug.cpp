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
    if (!texture || texture->m_type == Render::TEXTURE_EXTERNAL || texture->m_size.x < 16 || texture->m_size.y < 16)
        return false;
    const float scale = std::min(1.0, 1024.0 / std::max(texture->m_size.x, texture->m_size.y));
    const int width = std::max(1, int(texture->m_size.x * scale));
    const int height = std::max(1, int(texture->m_size.y * scale));

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
    GLuint framebuffers[2], buffer;
    glGenFramebuffers(2, framebuffers);
    glGenRenderbuffers(1, &buffer);
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
        glDeleteRenderbuffers(1, &buffer);
    });
    glDisable(GL_SCISSOR_TEST);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffers[0]);
    glFramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture->m_texID, 0);
    if (glCheckFramebufferStatus(GL_READ_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) return false;
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffers[1]);
    glBindRenderbuffer(GL_RENDERBUFFER, buffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, width, height);
    glFramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, buffer);
    if (glCheckFramebufferStatus(GL_DRAW_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) return false;
    glBlitFramebuffer(0, 0, texture->m_size.x, texture->m_size.y, 0, 0, width, height, GL_COLOR_BUFFER_BIT, GL_LINEAR);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffers[1]);
    glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
    glPixelStorei(GL_PACK_ALIGNMENT, 1);
    glPixelStorei(GL_PACK_ROW_LENGTH, 0);
    glPixelStorei(GL_PACK_SKIP_ROWS, 0);
    glPixelStorei(GL_PACK_SKIP_PIXELS, 0);
    std::vector<uint8_t> pixels(size_t(width) * height * 4);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels.data());
    m_rectangles = Fhud::detectRectangles(pixels, width, height);
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
    if (count)
        glUniform4fv(glGetUniformLocation(program, "fhudRectangleBounds[0]"), count, cache->m_rectangles.front().data());
    glUseProgram(previous);
}

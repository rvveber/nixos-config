#pragma once

#include "Rectangles.hpp"
#include "Refinement.hpp"
#include <hyprland/src/protocols/core/Compositor.hpp>
#include <hyprland/src/render/Texture.hpp>
#include <memory>

class FhudRectangleDebug {
  public:
    void observe(const SP<CWLSurfaceResource>& surface);
    static void apply(GLuint program, const std::shared_ptr<FhudRectangleDebug>& cache, const SP<Render::ITexture>& texture);

  private:
    bool update(const SP<Render::ITexture>& texture);
    WP<CWLSurfaceResource> m_surface;
    CHyprSignalListener m_commit;
    bool m_dirty = true;
    std::vector<Fhud::Rectangle> m_rectangles;
    std::vector<std::array<float, 4>> m_cornerRadii;
};

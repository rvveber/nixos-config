# Builds and validates the per-window FutureHUD shader.
{pkgs}: let
  appearance = import ../appearance.nix;
  theme = import ../theme.nix;
  accent = pkgs.lib.removePrefix "#" theme.base0C;
  channel = offset: toString (pkgs.lib.fromHexString (builtins.substring offset 2 accent));
in
  pkgs.stdenv.mkDerivation {
    pname = "fhud-holographic-shader";
    version = "1";
    src = ./.;
    nativeBuildInputs = [pkgs.pkg-config];
    buildInputs = [pkgs.libglvnd];
    postPatch = ''
      substituteInPlace holographic.glsl \
        --replace-fail '@accent@' '${channel 0}, ${channel 2}, ${channel 4}' \
        --replace-fail '@strength@' '${toString appearance.window.edgeStrength}' \
        --replace-fail '@depth@' '${toString appearance.window.edgeDepth}' \
        --replace-fail '@panelOpacity@' '${toString appearance.window.panelOpacity}' \
        --replace-fail '@panelTint@' '${toString appearance.window.panelTint}'
    '';
    buildPhase = ''
      runHook preBuild
      $CC -Wall -Wextra -Werror tests/render.c -o shader-check $(pkg-config --cflags --libs egl glesv2)
      runHook postBuild
    '';
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      export EGL_PLATFORM=surfaceless
      export LIBGL_ALWAYS_SOFTWARE=1
      export MESA_SHADER_CACHE_DISABLE=true
      export __EGL_VENDOR_LIBRARY_FILENAMES=${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json
      ./shader-check holographic.glsl
      runHook postCheck
    '';
    installPhase = ''
      mkdir -p $out
      cp holographic.glsl $out/
    '';
  }

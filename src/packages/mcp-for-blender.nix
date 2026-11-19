# Packages MCP for Blender with its matching declarative Blender extension.
#
# Why local: nixpkgs does not package it, and the PyPI release installs its
# Blender add-on imperatively (`uvx mcp-for-blender install-addon`); this build
# ships the add-on as a declarative extension with telemetry and update checks
# disabled. Upstream still requires the MCP 1 SDK.
# Remove when: nixpkgs packages it with its extension; drop the MCP 1 pin once
# upstream supports the MCP 2 SDK.
{
  lib,
  fetchFromGitHub,
  formats,
  python3,
}: let
  # Upstream requires mcp<2 while nixpkgs' default is the MCP 2 SDK.
  python = python3.override {
    self = python;
    packageOverrides = _: super: {mcp = super.mcp_1;};
  };
  python3Packages = python.pkgs;
in
  python3Packages.buildPythonApplication (finalAttrs: {
    pname = "mcp-for-blender";
    version = "2.3.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "ahujasid";
      repo = "mcp-for-blender";
      rev = "2662ce0e91931717545834bc3e6574a80bb3933c";
      hash = "sha256-8BLvNG21RIhK/3YQ54PYcP3cMGlPVDOBSPuT7B73Vyc=";
    };

    # Keep host transport and scene-independent configuration behind the package.
    # Upstream omits its telemetry config from Git; source builds supply a disabled one.
    patches = [./mcp-for-blender/nix-integration.patch];
    patchFlags = ["-p1" "--fuzz=0"];
    postPatch = ''
      cp addon.py src/blender_mcp/bundled/addon.py
    '';

    build-system = [python3Packages.setuptools];
    dependencies = with python3Packages; [
      httpx
      mcp
    ];

    postInstall = let
      manifest = (formats.toml {}).generate "blender-assets-manifest.toml" {
        schema_version = "1.0.0";
        id = "mcp_assets";
        inherit (finalAttrs) version;
        name = "Blender Assets";
        tagline = "Asset libraries, model generation and visual checks";
        maintainer = "Siddharth Ahuja";
        type = "add-on";
        blender_version_min = "5.1.0";
        license = ["SPDX:MIT"];
        permissions = {
          network = "Connect to the local MCP backend and asset providers";
          files = "Download assets and capture visual checks";
        };
      };
    in ''
      extension="$out/share/blender/extensions/mcp_assets"
      mkdir -p "$extension"
      cp addon.py "$extension/__init__.py"
      # Blender's extension loader deletes the legacy bl_info global.
      substituteInPlace "$extension/__init__.py" --replace-fail bl_info ADDON_INFO
      cp ${manifest} "$extension/blender_manifest.toml"
    '';
    passthru.extension = "${finalAttrs.finalPackage}/share/blender/extensions/mcp_assets";

    doCheck = false;
    pythonImportsCheck = ["blender_mcp.server"];

    meta = {
      description = "Blender asset libraries, model generation and visual verification through MCP";
      homepage = "https://github.com/ahujasid/mcp-for-blender";
      license = lib.licenses.mit;
      mainProgram = "mcp-for-blender";
      platforms = lib.platforms.linux;
    };
  })

# Packages MCP for Blender with its matching declarative Blender extension.
{
  lib,
  fetchFromGitHub,
  formats,
  python3Packages,
}:
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "mcp-for-blender";
  version = "2.1.9";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ahujasid";
    repo = "mcp-for-blender";
    rev = "7a0373ec9199183cb460068c4f96aed9c579fb4f";
    hash = "sha256-bL8x9AMHbQKX0e3pLDrlzndY5xUD1ApKBPaRCTHn45Q=";
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

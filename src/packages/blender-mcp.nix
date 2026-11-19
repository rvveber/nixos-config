# Packages the official Blender Lab MCP server and its matching Blender extension.
#
# Why local: nixpkgs does not package it, and the PyPI name `blender-mcp`
# belongs to a different project. Upstream still requires the MCP 1 SDK.
# Remove when: nixpkgs packages the Blender Lab server; drop the MCP 1 pin once
# upstream supports the MCP 2 SDK.
{
  lib,
  fetchgit,
  python3,
}: let
  # Upstream requires mcp<2 while nixpkgs' default is the MCP 2 SDK.
  python = python3.override {
    self = python;
    packageOverrides = _: super: {mcp = super.mcp_1;};
  };
  python3Packages = python.pkgs;
in
  python3Packages.buildPythonApplication rec {
    pname = "blender-mcp";
    version = "1.0.3";
    pyproject = true;

    # The PyPI package named blender-mcp belongs to a different project.
    src = fetchgit {
      url = "https://projects.blender.org/lab/blender_mcp.git";
      rev = "2cea8d566dde07fbac28a61d698909d69724e853";
      hash = "sha256-pYeByO4Oi5eyynsJhGVd1vBWXHvhGn+Y5LGit6Kazlw=";
    };
    sourceRoot = "${src.name}/mcp";

    build-system = [python3Packages.setuptools];
    dependencies = with python3Packages; [
      docutils
      mcp
      pyyaml
    ];
    passthru.extension = "${src}/addon/blender_mcp_addon";

    doCheck = false;
    pythonImportsCheck = ["blmcp"];

    meta = {
      description = "Official Blender Lab MCP server with Python execution and visual inspection";
      homepage = "https://www.blender.org/lab/mcp-server/";
      license = lib.licenses.gpl3Plus;
      mainProgram = "blender-mcp";
      platforms = lib.platforms.linux;
    };
  }

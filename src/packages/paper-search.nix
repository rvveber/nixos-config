# Packages the academic paper search MCP server from its upstream release.
#
# Why local: nixpkgs does not package it. It depends on FastMCP, and nixpkgs'
# FastMCP 3 does not support the MCP 2 SDK that nixpkgs now defaults to.
# Remove when: nixpkgs packages it; drop the MCP 1 pin once nixpkgs' FastMCP
# supports the MCP 2 SDK.
{
  lib,
  fetchFromGitHub,
  python3,
}: let
  # FastMCP 3 does not support the MCP 2 SDK yet; nixpkgs marks that pairing broken.
  python = python3.override {
    self = python;
    packageOverrides = _: super: {mcp = super.mcp_1;};
  };
  python3Packages = python.pkgs;
in
  python3Packages.buildPythonApplication rec {
    pname = "paper-search-mcp";
    version = "0.1.4";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "openags";
      repo = "paper-search-mcp";
      rev = "c8b642183bb725f0a7faec89e58b558df09079d1";
      sha256 = "0vpdm44xcxgcvlf9jbkx2ppq8j0p5afbyjbr8d73y3wmjm8z14cd";
    };

    build-system = [python3Packages.hatchling];
    dependencies = with python3Packages; [
      beautifulsoup4
      fastmcp
      feedparser
      httpx
      httpx-socks
      lxml
      mcp
      pypdf
      requests
    ];

    doCheck = false;
    pythonImportsCheck = ["paper_search_mcp.server"];

    meta = {
      description = "Academic literature search MCP server";
      homepage = "https://github.com/openags/paper-search-mcp";
      license = lib.licenses.mit;
      mainProgram = "paper-search-mcp";
      platforms = lib.platforms.linux;
    };
  }

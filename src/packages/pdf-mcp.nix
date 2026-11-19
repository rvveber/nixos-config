# Packages the PDF analysis server with native OCR and semantic-search dependencies.
#
# Why local: nixpkgs' `pdf-mcp` lags far behind upstream and lacks the
# semantic-search (fastembed) and HTTP entry points this configuration uses.
# Upstream releases after 3.6.0 require FastMCP 4 and the MCP 2 SDK, which
# nixpkgs does not provide together yet.
# Remove when: nixpkgs' `pdf-mcp` reaches this version with fastembed support;
# drop the MCP 1 pin once nixpkgs' FastMCP supports the MCP 2 SDK.
{
  lib,
  fetchFromGitHub,
  makeWrapper,
  python3,
  tesseract,
  writableTmpDirAsHomeHook,
}: let
  # FastMCP 3 does not support the MCP 2 SDK yet; nixpkgs marks that pairing broken.
  python = python3.override {
    self = python;
    packageOverrides = _: super: {mcp = super.mcp_1;};
  };
  python3Packages = python.pkgs;
in
  python3Packages.buildPythonApplication rec {
    pname = "pdf-mcp";
    version = "3.6.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "jztan";
      repo = "pdf-mcp";
      tag = "v${version}";
      hash = "sha256-vEWeDXqG1cyFt7+kiIBcZnczf+mAsR1slZhU0FTAWsU=";
    };

    build-system = [python3Packages.hatchling];
    dependencies = with python3Packages;
      [
        click
        fastembed
        fastmcp-slim
        httpx
        joserfc
        mcp
        numpy
        packaging
        pdfplumber
        pillow
        pydantic
        pydantic-settings
        pygments
        pypdf
        pypdfium2
        pytesseract
        snowballstemmer
      ]
      ++ fastmcp-slim.optional-dependencies.server;

    # Nixpkgs' dependency-slim distribution provides the same `fastmcp`
    # module; its deliberately distinct package metadata does not satisfy the
    # upstream wheel name even though the required server extras are present.
    pythonRemoveDeps = ["fastmcp"];
    # pdf-mcp does not import joserfc itself; its declared floor is ahead of nixpkgs.
    pythonRelaxDeps = ["joserfc"];

    nativeBuildInputs = [
      makeWrapper
      writableTmpDirAsHomeHook
    ];
    postFixup = ''
      for program in pdf-mcp pdf-mcp-http pdf-mcp-warm; do
        wrapProgram "$out/bin/$program" --prefix PATH : ${lib.makeBinPath [tesseract]}
      done
    '';

    doCheck = false;
    pythonImportsCheck = ["pdf_mcp.server"];

    meta = {
      description = "Agentic PDF search, extraction, rendering and OCR MCP server";
      homepage = "https://github.com/jztan/pdf-mcp";
      license = lib.licenses.mit;
      mainProgram = "pdf-mcp";
      platforms = lib.platforms.linux;
    };
  }

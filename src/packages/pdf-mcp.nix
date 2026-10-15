# Packages the PDF analysis server with native OCR and semantic-search dependencies.
{
  lib,
  fetchFromGitHub,
  makeWrapper,
  python3Packages,
  tesseract,
}: let
  pydantic-settings = python3Packages.pydantic-settings.overridePythonAttrs (old: rec {
    version = "2.14.2";
    src = fetchFromGitHub {
      owner = "pydantic";
      repo = "pydantic-settings";
      tag = "v${version}";
      sha256 = "10rbmqwxa89gfa13xk5x7l7yjna79bcbznm7gfprj61aznphj7gf";
    };
    dependencies = old.dependencies ++ [python3Packages.typing-inspection];
  });
  mcp = python3Packages.mcp.overridePythonAttrs (old: {
    dependencies = map (dependency:
      if (dependency.pname or "") == "pydantic-settings"
      then pydantic-settings
      else dependency)
    old.dependencies;
  });
  fastmcp-slim = python3Packages.fastmcp-slim.overridePythonAttrs (old: {
    dependencies = map (dependency:
      if (dependency.pname or "") == "pydantic-settings"
      then pydantic-settings
      else dependency)
    old.dependencies;
    optional-dependencies =
      old.optional-dependencies
      // {
        server = map (dependency:
          if (dependency.pname or "") == "mcp"
          then mcp
          else dependency)
        old.optional-dependencies.server;
      };
  });
in
  python3Packages.buildPythonApplication rec {
    pname = "pdf-mcp";
    version = "3.5.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "jztan";
      repo = "pdf-mcp";
      tag = "v${version}";
      sha256 = "1gk0zaf903ban3kiiznxlhas2i3c1xdjiv73nylk0279dp8p0psn";
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

    nativeBuildInputs = [makeWrapper];
    postFixup = ''
      for program in pdf-mcp pdf-mcp-http pdf-mcp-warm; do
        wrapProgram "$out/bin/$program" --prefix PATH : ${lib.makeBinPath [tesseract]}
      done
    '';

    doCheck = false;
    PDF_MCP_CACHE_DIR = "/build/pdf-mcp-cache";
    pythonImportsCheck = ["pdf_mcp.server"];

    meta = {
      description = "Agentic PDF search, extraction, rendering and OCR MCP server";
      homepage = "https://github.com/jztan/pdf-mcp";
      license = lib.licenses.mit;
      mainProgram = "pdf-mcp";
      platforms = lib.platforms.linux;
    };
  }

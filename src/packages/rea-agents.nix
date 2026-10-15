# Packages REA's versioned CLI and MCP server from its official source release.
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage rec {
  pname = "rea-agents";
  version = "6.5.0";

  src = fetchFromGitHub {
    owner = "morluto";
    repo = "rea";
    rev = "rea-agents-${version}";
    hash = "sha256-fPe+tqkSRR5K+zSVWb6kjI6/HbQSJ8DHjLJwSWu8NzI=";
  };

  npmDepsHash = "sha256-EQKhS1S7Hsfjbo5GikMeAFc2HFtALsDcw6XnJATUryw=";
  # The optional Frida dependency downloads artifacts during npm's install
  # hook. REA itself and its prebuilt node-pty dependency work without it.
  npmFlags = ["--ignore-scripts"];

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/rea --version | grep -Fx ${version}
    runHook postInstallCheck
  '';

  meta = {
    description = "Reverse-engineering CLI and MCP server";
    homepage = "https://github.com/morluto/rea";
    license = lib.licenses.mit;
    mainProgram = "rea";
    platforms = lib.platforms.linux;
  };
}

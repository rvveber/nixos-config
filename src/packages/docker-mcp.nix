{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "docker-mcp";
  version = "0.43.3";

  src = fetchFromGitHub {
    owner = "docker";
    repo = "mcp-gateway";
    rev = "v${version}";
    hash = "sha256-UE0VaFnFzVdEnRP83lwQvdt/qJRrR1j28BWtyJ+1O0Y=";
  };

  vendorHash = null;
  subPackages = ["cmd/docker-mcp"];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/docker/mcp-gateway/cmd/docker-mcp/version.Version=v${version}"
  ];

  doCheck = false;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/docker-mcp --help >/dev/null
    $out/bin/docker-mcp --version | grep -F "v${version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Docker MCP Gateway CLI plugin";
    homepage = "https://github.com/docker/mcp-gateway";
    license = lib.licenses.mit;
    mainProgram = "docker-mcp";
    platforms = lib.platforms.linux;
  };
}

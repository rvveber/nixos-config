# Adds local PDF reading and analysis to the shared Docker MCP gateway.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  paperDirectory = "${config.xdg.stateHome}/docker-mcp-gateway/papers";
  server = pkgs.writeText "pdf.yaml" ''
    name: pdf
    title: PDF
    description: Analyze locally available PDFs, including text, tables, charts, scans, and rendered pages; use `paper-retrieve` to acquire papers first
    type: server
    image: ghcr.io/jztan/pdf-mcp:3.2.0@sha256:e6787ef328005fdf69e73162e27d7f4fbcc764192950b400b2792d433ac90e92
    command:
      - pdf-mcp
    volumes:
      - ${paperDirectory}:/data/papers:ro
    disableNetwork: true
  '';
in {
  imports = [../application/docker-mcp-gateway.nix];

  config = lib.mkIf osConfig.virtualisation.docker.enable {
    services.dockerMcpGateway.allowedReadOnlyPaths = [paperDirectory];
    services.dockerMcpGateway.serverFiles = [server];
  };
}

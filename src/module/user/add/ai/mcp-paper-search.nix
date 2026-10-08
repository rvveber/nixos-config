# Adds the paper-search server to the shared Docker MCP gateway.
{
  lib,
  osConfig,
  pkgs,
  ...
}: let
  server = pkgs.writeText "paper-search.yaml" ''
    name: paper-search
    title: Paper Search
    description: Discover and deduplicate academic literature across scholarly indexes; use `paper-retrieve` for full text, then `pdf` for local document analysis
    type: server
    image: mcp/paper-search@sha256:19d0af269a5531403fbb042aad8277d1a9ec2315c972769c7ca8efb3a76eca34
  '';
in {
  imports = [../application/docker-mcp-gateway.nix];

  config = lib.mkIf osConfig.virtualisation.docker.enable {
    services.dockerMcpGateway.serverFiles = [server];
    services.dockerMcpGateway.toolAllowlist.paper-search = ["search_papers"];
  };
}

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
    description: Discover and deduplicate academic literature across scholarly indexes; use `paper-retrieve` when full text is unavailable through open sources or when searching books
    type: server
    image: mcp/paper-search@sha256:19d0af269a5531403fbb042aad8277d1a9ec2315c972769c7ca8efb3a76eca34
  '';
in {
  config = lib.mkIf osConfig.virtualisation.docker.enable {
    services.dockerMcpGateway.serverFiles = [server];
  };
}

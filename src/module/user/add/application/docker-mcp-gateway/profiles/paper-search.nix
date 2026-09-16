# Declares the paper-search Docker MCP profile for open scholarly discovery.
{
  lib,
  osConfig,
  pkgs,
  ...
}: let
  server = pkgs.writeText "paper-search.yaml" ''
    name: paper-search
    title: Paper Search
    description: Startingpoint for discovering academic papers. `paper-retrieve` is preferred for actually accessing the contents and for searching books.
    type: server
    image: mcp/paper-search@sha256:19d0af269a5531403fbb042aad8277d1a9ec2315c972769c7ca8efb3a76eca34
  '';
in {
  config = lib.mkIf osConfig.virtualisation.docker.enable {
    services.dockerMcpGateway.profiles.paper-search = {
      title = "Paper Search";
      port = 8811;
      serverFiles = [server];
    };
  };
}

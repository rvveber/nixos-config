# Provides focused academic discovery through the shared MCP gateway.
{
  lib,
  pkgs,
  ...
}: let
  server = pkgs.callPackage ../../../../packages/paper-search.nix {};
in {
  imports = [../application/mcp-gateway.nix];

  services.mcpGateway.servers.paper-search = {
    command = lib.getExe server;
    tools = ["search_papers"];
  };
}

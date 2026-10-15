# Provides REA with native host access and a compatible Ghidra toolchain through MCP.
{
  lib,
  pkgs,
  ...
}: let
  rea = pkgs.callPackage ../../../../packages/rea-agents.nix {};
in {
  imports = [../application/mcp-gateway.nix];

  home.packages = [rea pkgs.ghidra];

  services.mcpGateway.servers.rea = {
    command = lib.getExe rea;
    args = ["mcp"];
    environment = {
      GHIDRA_INSTALL_DIR = "${pkgs.ghidra}/lib/ghidra";
      JAVA_HOME = toString pkgs.jdk21;
    };
  };
}

# Provides REA with native host access and a compatible Ghidra toolchain through MCP.
{
  lib,
  pkgs,
  ...
}: {
  imports = [../application/mcp-gateway.nix];

  home.packages = [pkgs.rea pkgs.ghidra];

  services.mcpGateway.servers.rea = {
    command = lib.getExe pkgs.rea;
    args = ["mcp"];
    environment = {
      GHIDRA_INSTALL_DIR = "${pkgs.ghidra}/lib/ghidra";
      JAVA_HOME = toString pkgs.jdk21;
    };
  };
}

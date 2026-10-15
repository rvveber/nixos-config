# Provides native local and remote PDF analysis through the shared MCP gateway.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.mcpPdf;
  server = pkgs.callPackage ../../../../packages/pdf-mcp.nix {};
  cacheDirectory = "${config.xdg.cacheHome}/pdf-mcp";
  pdfConfig = (pkgs.formats.toml {}).generate "pdf-mcp-config.toml" {
    paths.allow = map (directory: "${directory}/**") cfg.documentDirectories;
  };
in {
  imports = [../application/mcp-gateway.nix];

  options.services.mcpPdf.documentDirectories = lib.mkOption {
    type = lib.types.listOf (lib.types.addCheck lib.types.nonEmptyStr (lib.hasPrefix "/"));
    default = [];
    description = "Existing host directories the PDF server may read.";
  };

  config = {
    home.activation.createPdfDirectories = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.coreutils}/bin/install -d -m 0700 ${lib.escapeShellArg cacheDirectory}
    '';
    xdg.configFile."pdf-mcp/config.toml".source = pdfConfig;

    services.mcpGateway.servers.pdf = {
      command = lib.getExe server;
      environment = {
        FASTEMBED_CACHE_PATH = "${cacheDirectory}/fastembed";
        PDF_MCP_CACHE_DIR = cacheDirectory;
        PDF_MCP_UPDATE_CHECK = "false";
      };
    };
  };
}

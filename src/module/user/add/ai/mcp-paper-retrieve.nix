# Retrieves scholarly documents into a private directory shared with the PDF server.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.mcpPaperRetrieve;
  retrieval = pkgs.callPackage ../../../../packages/libgen-mcp.nix {};
  absolutePath = lib.types.addCheck lib.types.nonEmptyStr (lib.hasPrefix "/");
in {
  imports = [../application/mcp-gateway.nix];

  options.services.mcpPaperRetrieve.downloadDirectory = lib.mkOption {
    type = absolutePath;
    # Keep downloaded documents available across the gateway migration.
    default = "${config.xdg.stateHome}/docker-mcp-gateway/papers";
    description = "Private destination for retrieved documents.";
  };

  config = {
    home.activation.createPaperDirectory = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.coreutils}/bin/install -d -m 0700 ${lib.escapeShellArg cfg.downloadDirectory}
    '';

    services.mcpGateway.servers.paper-retrieve = {
      command = lib.getExe retrieval;
      environment = {
        LIBGEN_MCP_REMOTE_DOWNLOADS = "false";
        LIBGEN_MCP_SERVER_FETCH = "true";
        LIBGEN_MCP_DOWNLOAD_DIR = cfg.downloadDirectory;
        LIBGEN_MCP_CONFIRM_DOWNLOADS = "false";
      };
      tools = [
        "get_details"
        "download"
      ];
    };
  };
}

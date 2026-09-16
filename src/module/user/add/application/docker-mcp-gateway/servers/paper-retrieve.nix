# Adds the libgen-mcp retrieval server to the shared Docker MCP gateway.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  stateRoot = "${config.xdg.stateHome}/docker-mcp-gateway";
  paperDirectory = "${stateRoot}/papers";
  server = pkgs.writeText "paper-retrieve.yaml" ''
    name: paper-retrieve
    title: Paper Retrieve
    description: Retrieve paper and book contents by DOI or MD5; use `paper-search` for discovery, then pass locally downloaded files to `pdf`
    type: server
    image: ghcr.io/jmrplens/libgen-mcp:1.7.2@sha256:fd41aaa926f3ce996e0e65042d2b55a8843b41f99898b96157d3e9ad88815426
    volumes:
      - ${paperDirectory}:/data/papers:rw
    env:
      - name: LIBGEN_MCP_REMOTE_DOWNLOADS
        value: "false"
      - name: LIBGEN_MCP_SERVER_FETCH
        value: "true"
      - name: LIBGEN_MCP_DOWNLOAD_DIR
        value: /data/papers
      - name: LIBGEN_MCP_CONFIRM_DOWNLOADS
        value: "false"
  '';
in {
  config = lib.mkIf osConfig.virtualisation.docker.enable {
    home.activation.createPaperDirectory = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.coreutils}/bin/install -d -m 0700 ${lib.escapeShellArg stateRoot}
      ${pkgs.coreutils}/bin/install -d -m 0777 ${lib.escapeShellArg paperDirectory}
    '';

    services.dockerMcpGateway.allowedWritablePaths = [paperDirectory];
    services.dockerMcpGateway.serverFiles = [server];
    services.dockerMcpGateway.toolAllowlist.paper-retrieve = [
      "get_details"
      "download"
      "read"
    ];
  };
}

# Adds the libgen-mcp retrieval server to the shared Docker MCP gateway.
{
  lib,
  osConfig,
  pkgs,
  ...
}: let
  server = pkgs.writeText "paper-retrieve.yaml" ''
    name: paper-retrieve
    title: Paper Retrieve
    description: Retrieve paper and book contents by DOI or MD5; use `paper-search` for broad multi-source academic discovery
    type: server
    image: ghcr.io/jmrplens/libgen-mcp:1.7.2@sha256:fd41aaa926f3ce996e0e65042d2b55a8843b41f99898b96157d3e9ad88815426
    env:
      - name: LIBGEN_MCP_REMOTE_DOWNLOADS
        value: "true"
      - name: LIBGEN_MCP_SERVER_FETCH
        value: "true"
  '';
in {
  config = lib.mkIf osConfig.virtualisation.docker.enable {
    services.dockerMcpGateway.serverFiles = [server];
    services.dockerMcpGateway.toolAllowlist.paper-retrieve = [
      "get_details"
      "download"
      "read"
    ];
  };
}

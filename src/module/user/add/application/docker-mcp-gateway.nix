# Runs Docker MCP Gateway as one authenticated, per-user HTTP endpoint shared
# by local AI harnesses. It requires Docker Engine; compatibility layers that
# expose a Docker-like CLI, including Podman, are outside this module's scope.
#
# Data flow:
#   harness -> http://127.0.0.1:8811/mcp -> gateway -> MCP server containers
#
# The module owns the service and its safe runtime boundary. Docker's mutable
# state under ~/.docker/mcp/ owns catalogs, enabled servers, tools and server
# configuration. Harness configuration remains manual and belongs to each
# harness. The gateway watches Docker's configuration and reloads changes.
#
# The endpoint is loopback-only and still uses a bearer token because any
# client holding it may invoke every exposed tool. The token is an opaque random
# value: its contents have no meaning, it only needs to remain private and match
# the client header. It is generated once with mode 0600. Delete the file and
# restart the service to rotate it.
#
# Runtime endpoints and operations:
#   MCP:      http://127.0.0.1:8811/mcp
#   Health:   http://127.0.0.1:8811/health
#   Token:    ~/.local/state/docker-mcp-gateway/auth-token
#   Status:   systemctl --user status docker-mcp-gateway
#   Logs:     journalctl --user --unit docker-mcp-gateway --follow
#
# Docker selects its default profile when profiles are enabled and otherwise
# reads its legacy catalog/config files. This module deliberately leaves that
# selection to Docker. Local server definitions belong below
# ~/.docker/mcp/catalogs/ and should pin images, declare allowHosts and expose
# only required tools.
#
# Harnesses send `Authorization: Bearer <token>`. Load the token into shells:
#   export MCP_GATEWAY_AUTH_TOKEN="$(cat \
#     "$HOME/.local/state/docker-mcp-gateway/auth-token")"
#
# Codex (~/.codex/config.toml):
#   [mcp_servers.docker_mcp_gateway]
#   url = "http://127.0.0.1:8811/mcp"
#   bearer_token_env_var = "MCP_GATEWAY_AUTH_TOKEN"
#
# Claude Code (.mcp.json) and Cursor use mcpServers.<name>.url plus an
# Authorization header. VS Code uses servers.<name>; Gemini CLI uses
# mcpServers.<name>.httpUrl. OpenCode uses a remote MCP entry whose header is
# `Bearer {env:MCP_GATEWAY_AUTH_TOKEN}`.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.services.dockerMcpGateway;
  dockerMcp = pkgs.callPackage ../../../../packages/docker-mcp.nix {};
  authTokenFile = "${config.xdg.stateHome}/docker-mcp-gateway/auth-token";
  absolutePath =
    lib.types.addCheck lib.types.nonEmptyStr (path:
      lib.hasPrefix "/" path && !lib.hasInfix ":" path);
  gatewayArguments =
    [
      "gateway"
      "run"
      "--transport=streaming"
      "--host=127.0.0.1"
      "--port=${toString cfg.port}"
      "--block-network=true"
    ]
    ++ lib.optionals (cfg.secretFiles != []) [
      "--secrets=${lib.concatStringsSep ":" cfg.secretFiles}"
    ];

  launcher = pkgs.writeShellApplication {
    name = "docker-mcp-gateway";
    runtimeInputs = [pkgs.coreutils pkgs.openssl];
    text = ''
      auth_token_file=${lib.escapeShellArg authTokenFile}
      install -d -m 0700 "$(dirname "$auth_token_file")"

      if [ ! -s "$auth_token_file" ]; then
        umask 077
        openssl rand -hex 32 > "$auth_token_file"
      fi

      chmod 0600 "$auth_token_file"
      export MCP_GATEWAY_AUTH_TOKEN="$(cat "$auth_token_file")"

      exec ${lib.getExe dockerMcp} ${lib.escapeShellArgs gatewayArguments}
    '';
  };
in {
  options.services.dockerMcpGateway = {
    enable = lib.mkEnableOption "a shared per-user Docker MCP Gateway";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8811;
      description = "Loopback port for the Streamable HTTP endpoint.";
    };

    secretFiles = lib.mkOption {
      type = lib.types.listOf absolutePath;
      default = [];
      description = ''
        Runtime .env files used to resolve catalog-declared Docker MCP secrets.
        Keep them outside the Nix store and readable only by this user. Custom
        secret files make Docker use its legacy catalog/config mode because the
        current gateway cannot combine them with a named profile.
      '';
    };

    allowedReadOnlyPaths = lib.mkOption {
      type = lib.types.listOf absolutePath;
      default = [];
      description = ''
        Absolute host directory roots that catalog entries may mount read-only.
        An empty list grants no additional host filesystem access.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = osConfig.virtualisation.docker.enable;
        message = "services.dockerMcpGateway requires Docker Engine.";
      }
    ];

    home.file.".docker/cli-plugins/docker-mcp".source = lib.getExe dockerMcp;

    systemd.user.services.docker-mcp-gateway = {
      Unit.Description = "Docker MCP Gateway";

      Service = {
        Environment = lib.optionals (cfg.allowedReadOnlyPaths != []) [
          "MCP_GATEWAY_DOCKER_BIND_ALLOWED_PATHS=${lib.concatStringsSep ":" cfg.allowedReadOnlyPaths}"
        ];
        ExecStart = lib.getExe launcher;
        Restart = "on-failure";
        RestartSec = "5s";
        UMask = "0077";
      };

      Install.WantedBy = ["default.target"];
    };
  };
}

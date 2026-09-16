# Runs Docker MCP Gateway as an authenticated per-user HTTP bridge between local
# AI harnesses and Docker-managed MCP server containers. Docker Engine is
# required; compatibility layers such as Podman are outside this module's scope.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.services.dockerMcpGateway;
  dockerMcp = pkgs.callPackage ../../../../packages/docker-mcp.nix {};

  # The token has no embedded meaning. Its secrecy is what prevents unrelated
  # local clients from invoking every tool exposed by the gateway. Removing it
  # and restarting the service creates a new token.
  authTokenFile = "${config.xdg.stateHome}/docker-mcp-gateway/auth-token";
  absolutePath =
    lib.types.addCheck lib.types.nonEmptyStr (path:
      lib.hasPrefix "/" path && !lib.hasInfix ":" path);

  # Keep only this module's runtime boundary explicit. Docker owns mutable
  # catalog, profile and tool state below ~/.docker/mcp/ and supplies its own
  # resource, logging, signature-verification and reload defaults.
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

    # The plugin manages catalogs and servers; the service consumes Docker's
    # default profile or legacy configuration without depending on a working
    # directory. Local definitions belong below ~/.docker/mcp/catalogs/.
    home.file.".docker/cli-plugins/docker-mcp".source = lib.getExe dockerMcp;

    # Runtime contract:
    #   MCP:    http://127.0.0.1:8811/mcp
    #   Health: http://127.0.0.1:8811/health
    #   Token:  ~/.local/state/docker-mcp-gateway/auth-token
    #
    # Harnesses send `Authorization: Bearer <token>`. Shell-based clients can
    # load it with:
    #   export MCP_GATEWAY_AUTH_TOKEN="$(cat \
    #     "$HOME/.local/state/docker-mcp-gateway/auth-token")"
    #
    # Codex (~/.codex/config.toml):
    #   [mcp_servers.docker_mcp_gateway]
    #   url = "http://127.0.0.1:8811/mcp"
    #   bearer_token_env_var = "MCP_GATEWAY_AUTH_TOKEN"
    #
    # Claude Code and Cursor use mcpServers.<name>.url, VS Code uses
    # servers.<name>, Gemini CLI uses mcpServers.<name>.httpUrl and OpenCode
    # uses a remote MCP entry. Each sends the same Authorization header.
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

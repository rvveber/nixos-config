{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
# Shared per-user MCP endpoint for every local harness:
#   Streamable HTTP: http://127.0.0.1:8811/mcp
#   Health:          http://127.0.0.1:8811/health
#   Authentication:  Authorization: Bearer <token>
#   Token file:      ~/.local/state/mcp-gateway/auth-token (mode 0600)
#
# Operate after applying the host configuration:
#   systemctl --user status mcp-gateway
#   journalctl --user --unit mcp-gateway --follow
#   curl --fail http://127.0.0.1:8811/health
#
# Responsibility boundaries:
#   This module owns the package, loopback endpoint, user service, resource
#   limits, network policy, and gateway authentication token.
#   Docker MCP profiles and catalog entries own the enabled servers, tools,
#   mounts, and per-server network grants under ~/.docker/mcp/.
#   The user or host configuration owns credential decryption. Each catalog
#   entry declares which named secrets its server may receive; importing a
#   SOPS value into that resolver is an explicit local integration step.
#   Each harness owns its endpoint and Authorization-header configuration.
#
# A credentialed catalog entry can stay generic while its owner wires SOPS:
#   sops.templates.user_i_mcp_gateway_secrets.content =
#     "annas-mcp.api_key=${config.sops.placeholder.user_i_annas_api_key}";
#   services.mcpGateway.secretFiles =
#     [osConfig.sops.templates.user_i_mcp_gateway_secrets.path];
# The catalog maps annas-mcp.api_key to ANNAS_SECRET_KEY inside its container.
#
# Manage the gateway profile through the installed Docker CLI plugin:
#   docker mcp profile create --name Default --id default
#   docker mcp profile server add default --server file://servers/example.yaml
#   docker mcp profile tools default --enable SERVER_NAME.TOOL_NAME
#   systemctl --user restart mcp-gateway
# Local definitions must live below ~/.docker/mcp/catalogs/. Declare allowHosts
# for networked containers, use disableNetwork for offline containers, pin
# Docker MCP images by digest, and keep the tool allowlist narrow.
#
# Harness connection remains manual. This module deliberately does not call
# `docker mcp client connect` or write any harness configuration. Load the token
# for clients that support environment-backed headers:
#   export MCP_GATEWAY_AUTH_TOKEN="$(cat \
#     "$HOME/.local/state/mcp-gateway/auth-token")"
# Desktop applications must inherit that variable; otherwise use their secret
# store or an untracked per-user configuration with mode 0600.
#
# Codex (~/.codex/config.toml):
#   [mcp_servers.docker_gateway]
#   url = "http://127.0.0.1:8811/mcp"
#   bearer_token_env_var = "MCP_GATEWAY_AUTH_TOKEN"
#
# Claude Code (.mcp.json):
#   {"mcpServers":{"docker-gateway":{"type":"http",
#     "url":"http://127.0.0.1:8811/mcp",
#     "headers":{"Authorization":"Bearer ${MCP_GATEWAY_AUTH_TOKEN}"}}}}
#
# VS Code user mcp.json uses servers.<name> with type=http, the URL above, and
# an Authorization header backed by a password input such as
# ${input:mcp-gateway-token}. Cursor uses mcpServers.<name>.url and .headers.
# Gemini CLI uses mcpServers.<name>.httpUrl and .headers.
#
# OpenCode user opencode.json:
#   {"mcp":{"docker-gateway":{"type":"remote","oauth":false,
#     "url":"http://127.0.0.1:8811/mcp",
#     "headers":{"Authorization":"Bearer {env:MCP_GATEWAY_AUTH_TOKEN}"}}}}
#
# The gateway token protects only this HTTP endpoint. Credential-dependent MCP
# servers additionally declare named secrets in their catalog entry. Point
# secretFiles at a runtime-only, access-restricted file rendered by SOPS; its
# keys are Docker MCP secret names, not environment variable names. Docker MCP
# Gateway is pre-release software, so upgrades require a security review and a
# fresh activation-package build.
let
  cfg = config.services.mcpGateway;
  dockerMcp = pkgs.callPackage ../../../../packages/docker-mcp.nix {};
  tokenFile = "${config.xdg.stateHome}/mcp-gateway/auth-token";
  bindPath =
    lib.types.addCheck lib.types.str (path:
      lib.hasPrefix "/" path && !lib.hasInfix ":" path);
  secretFile =
    lib.types.addCheck lib.types.nonEmptyStr (path:
      lib.hasPrefix "/" path && !lib.hasInfix ":" path);
  gatewayArguments =
    [
      "gateway"
      "run"
      "--profile"
      cfg.profile
      "--transport"
      "streaming"
      "--host"
      "127.0.0.1"
      "--port"
      (toString cfg.port)
      "--cpus"
      (toString cfg.cpus)
      "--memory"
      cfg.memory
      "--block-network=true"
      "--block-secrets=true"
      "--log-calls=true"
      "--verify-signatures=true"
      "--watch=true"
    ]
    ++ lib.optionals (cfg.secretFiles != []) [
      "--secrets=${lib.concatStringsSep ":" cfg.secretFiles}"
    ]
    ++ lib.optional cfg.longLived "--long-lived";

  launcher = pkgs.writeShellApplication {
    name = "mcp-gateway";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.docker-client
      pkgs.openssl
    ];
    text = ''
      token_file=${lib.escapeShellArg tokenFile}
      token_directory="$(dirname "$token_file")"
      install -d -m 0700 "$token_directory"

      if [ ! -s "$token_file" ]; then
        temporary_file="$(mktemp "$token_directory/auth-token.XXXXXX")"
        trap 'rm -f "$temporary_file"' EXIT
        openssl rand -hex 32 > "$temporary_file"
        chmod 0600 "$temporary_file"
        mv "$temporary_file" "$token_file"
        trap - EXIT
      fi

      chmod 0600 "$token_file"
      MCP_GATEWAY_AUTH_TOKEN="$(cat "$token_file")"
      export MCP_GATEWAY_AUTH_TOKEN

      exec ${lib.getExe cfg.package} ${lib.escapeShellArgs gatewayArguments}
    '';
  };
in {
  options.services.mcpGateway = {
    enable = lib.mkEnableOption "a shared Docker MCP Gateway";

    package = lib.mkOption {
      type = lib.types.package;
      default = dockerMcp;
      defaultText = lib.literalExpression "pkgs.callPackage ../../../../packages/docker-mcp.nix {}";
      description = "Docker MCP Gateway package to use.";
    };

    profile = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "default";
      description = "Docker MCP profile exposed by the gateway.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8811;
      description = "Loopback port for the Streamable HTTP endpoint.";
    };

    cpus = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1;
      description = "CPU limit for each MCP server container.";
    };

    memory = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "2Gb";
      description = "Memory limit for each MCP server container.";
    };

    longLived = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Keep stateful MCP server containers alive until the gateway stops.";
    };

    secretFiles = lib.mkOption {
      type = lib.types.listOf secretFile;
      default = [];
      example = ["/run/secrets/rendered/mcp-gateway"];
      description = ''
        Runtime .env files used by Docker MCP to resolve catalog-declared
        secrets. Keep these files outside the Nix store and restrict them to
        this user; SOPS templates are the intended source.
      '';
    };

    readOnlyBindPaths = lib.mkOption {
      type = lib.types.listOf bindPath;
      default = [];
      example = ["/home/i/projects"];
      description = "Absolute host-path roots MCP servers may mount read-only.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = osConfig.virtualisation.docker.enable;
        message = "services.mcpGateway requires virtualisation.docker.enable.";
      }
    ];

    home.packages = [cfg.package];

    home.file.".docker/cli-plugins/docker-mcp".source = lib.getExe cfg.package;

    systemd.user.services.mcp-gateway = {
      Unit = {
        Description = "Shared Docker MCP Gateway";
        StartLimitIntervalSec = 0;
      };

      Service = {
        Environment = lib.optionals (cfg.readOnlyBindPaths != []) [
          "MCP_GATEWAY_DOCKER_BIND_ALLOWED_PATHS=${lib.concatStringsSep ":" cfg.readOnlyBindPaths}"
        ];
        ExecStart = lib.getExe launcher;
        Restart = "on-failure";
        RestartSec = "5s";
        UMask = "0077";
        WorkingDirectory = config.home.homeDirectory;
      };

      Install.WantedBy = ["default.target"];
    };
  };
}

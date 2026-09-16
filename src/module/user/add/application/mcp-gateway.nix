{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.services.mcpGateway;
  dockerMcp = pkgs.callPackage ../../../../packages/docker-mcp.nix {};
  tokenFile = "${config.xdg.stateHome}/mcp-gateway/auth-token";
  bindPath =
    lib.types.addCheck lib.types.str (path:
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
      "--block-secrets=true"
      "--verify-signatures=true"
      "--watch=true"
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

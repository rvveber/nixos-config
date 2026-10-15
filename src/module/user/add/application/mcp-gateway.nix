# Exposes declarative stdio MCP servers through one authenticated local endpoint.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.mcpGateway;
  json = pkgs.formats.json {};
  stateRoot = "${config.xdg.stateHome}/mcp-gateway";
  authTokenFile = "${stateRoot}/auth-token";
  legacyAuthTokenFile = "${config.xdg.stateHome}/docker-mcp-gateway/auth-token";
  absolutePath = lib.types.addCheck lib.types.nonEmptyStr (lib.hasPrefix "/");
  python = pkgs.python3.withPackages (pythonPackages:
    [pythonPackages.fastmcp-slim]
    ++ pythonPackages.fastmcp-slim.optional-dependencies.client
    ++ pythonPackages.fastmcp-slim.optional-dependencies.server);
  serverConfiguration = json.generate "mcp-gateway.json" {
    servers =
      lib.mapAttrs
      (_: server:
        {
          inherit (server) command args;
          env = server.environment;
          keep_alive = true;
        }
        // lib.optionalAttrs (server.workingDirectory != null) {
          cwd = server.workingDirectory;
        })
      cfg.servers;
    toolAllowlists = lib.mapAttrs (_: server: server.tools) cfg.servers;
  };
  initializeToken = pkgs.writeShellApplication {
    name = "initialize-mcp-gateway-token";
    runtimeInputs = [pkgs.coreutils pkgs.openssl];
    text = ''
      umask 077
      token_file=${lib.escapeShellArg authTokenFile}
      install -d -m 0700 "$(dirname "$token_file")"
      if [ ! -s "$token_file" ]; then
        legacy_token_file=${lib.escapeShellArg legacyAuthTokenFile}
        if [ -s "$legacy_token_file" ]; then
          install -m 0600 "$legacy_token_file" "$token_file"
        else
          openssl rand -hex 32 > "$token_file"
        fi
      fi
      chmod 0600 "$token_file"
    '';
  };
  headersHelper = pkgs.writeShellApplication {
    name = "mcp-gateway-headers";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      token="$(cat ${lib.escapeShellArg authTokenFile})"
      printf '{"Authorization":"Bearer %s"}\n' "$token"
    '';
  };
in {
  options.services.mcpGateway = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 8811;
      description = "Loopback port of the shared MCP endpoint.";
    };

    servers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          command = lib.mkOption {
            type = absolutePath;
            description = "Absolute path to the stdio MCP server executable.";
          };
          args = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Arguments passed to the MCP server executable.";
          };
          environment = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = {};
            description = "Environment added to the server process.";
          };
          workingDirectory = lib.mkOption {
            type = lib.types.nullOr absolutePath;
            default = null;
            description = "Optional working directory for the server process.";
          };
          tools = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.nonEmptyStr);
            default = null;
            description = "Optional tool allowlist; prompts and resources remain visible.";
          };
        };
      });
      default = {};
      description = "Stdio MCP servers mounted under their attribute names.";
    };
  };

  config = lib.mkIf (cfg.servers != {}) {
    home.packages = [headersHelper];

    programs.opencode.settings.mcp.gateway = lib.mkIf config.programs.opencode.enable {
      type = "remote";
      url = "http://127.0.0.1:${toString cfg.port}/mcp";
      enabled = true;
      oauth = false;
      headers.Authorization = "Bearer {file:${authTokenFile}}";
    };

    systemd.user.services.mcp-gateway = {
      Unit.Description = "FastMCP Gateway";
      Service = {
        Environment = [
          "HOME=${config.home.homeDirectory}"
          "XDG_CONFIG_HOME=${config.xdg.configHome}"
          "XDG_CACHE_HOME=${config.xdg.cacheHome}"
          "XDG_STATE_HOME=${config.xdg.stateHome}"
          "PYTHONUNBUFFERED=1"
        ];
        ExecStartPre = lib.getExe initializeToken;
        ExecStart = "${python}/bin/python ${./mcp-gateway.py} --config ${serverConfiguration} --token-file ${authTokenFile} --port ${toString cfg.port}";
        Restart = "on-failure";
        RestartSec = "5s";
        UMask = "0077";
      };
      Install.WantedBy = ["default.target"];
    };
  };
}

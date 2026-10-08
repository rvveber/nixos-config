# Runs Nix-declared Docker MCP servers behind one authenticated HTTP gateway
# while leaving other profiles available for interactive experimentation.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  gateway = config.services.dockerMcpGateway;
  dockerMcp = pkgs.callPackage ../../../../packages/docker-mcp.nix {};

  profileId = "nixos";
  port = 8811;
  stateRoot = "${config.xdg.stateHome}/docker-mcp-gateway";
  authTokenFile = "${stateRoot}/auth-token";
  catalogRoot = "${config.home.homeDirectory}/.docker/mcp/catalogs";
  absolutePath =
    lib.types.addCheck lib.types.nonEmptyStr (path:
      lib.hasPrefix "/" path && !lib.hasInfix ":" path);
  serverFileIndexes = lib.genList (index: index) (builtins.length gateway.serverFiles);
  serverReferences =
    gateway.serverReferences
    ++ map (index: "file://nixos/${toString index}.yaml") serverFileIndexes;

  profileReconciler = pkgs.writeShellApplication {
    name = "docker-mcp-profile";
    runtimeInputs = [pkgs.coreutils pkgs.openssl];
    text = ''
      umask 077
      catalog_root=${lib.escapeShellArg catalogRoot}
      profile_dir="$catalog_root/nixos"
      install -d -m 0700 "$profile_dir"

      auth_token_file=${lib.escapeShellArg authTokenFile}
      install -d -m 0700 "$(dirname "$auth_token_file")"
      if [ ! -s "$auth_token_file" ]; then
        openssl rand -hex 32 > "$auth_token_file"
      fi
      chmod 0600 "$auth_token_file"

      ${lib.getExe dockerMcp} feature enable profiles >/dev/null
      ${lib.getExe dockerMcp} feature enable tool-name-prefix >/dev/null

      ${
        lib.concatMapStringsSep "\n" (catalog: ''
          if ! ${lib.getExe dockerMcp} catalog pull ${lib.escapeShellArg catalog}; then
            printf 'Warning: could not refresh Docker MCP catalog %s\n' ${lib.escapeShellArg catalog} >&2
          fi
        '')
        gateway.catalogs
      }

      ${
        lib.concatMapStringsSep "\n" (
          index: let
            source = builtins.elemAt gateway.serverFiles index;
          in ''
            install -m 0600 ${lib.escapeShellArg source} "$profile_dir/${toString index}.yaml"
          ''
        )
        serverFileIndexes
      }

      if ${lib.getExe dockerMcp} profile show ${lib.escapeShellArg profileId} >/dev/null 2>&1; then
        ${lib.getExe dockerMcp} profile remove ${lib.escapeShellArg profileId}
      fi

      ${lib.getExe dockerMcp} profile create \
        --id ${lib.escapeShellArg profileId} \
        --name NixOS \
        ${lib.concatMapStringsSep " " (reference: "--server ${lib.escapeShellArg reference}") serverReferences}

      ${
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (server: tools: ''
            ${lib.getExe dockerMcp} profile tools ${lib.escapeShellArg profileId} \
              --disable-all ${lib.escapeShellArg server}
            ${lib.getExe dockerMcp} profile tools ${lib.escapeShellArg profileId} \
              ${lib.concatMapStringsSep " " (tool: "--enable ${lib.escapeShellArg "${server}.${tool}"}") tools}
          '')
          gateway.toolAllowlist
        )
      }
    '';
  };

  gatewayLauncher = pkgs.writeShellApplication {
    name = "docker-mcp-gateway";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      auth_token_file=${lib.escapeShellArg authTokenFile}
      MCP_GATEWAY_AUTH_TOKEN="$(cat "$auth_token_file")"
      export MCP_GATEWAY_AUTH_TOKEN

      exec ${lib.getExe dockerMcp} gateway run \
        --transport=streaming \
        --host=127.0.0.1 \
        --port=${toString port} \
        --block-network=true \
        --profile=${lib.escapeShellArg profileId}
    '';
  };

  headersHelper = pkgs.writeShellApplication {
    name = "docker-mcp-gateway-headers";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      token="$(cat ${lib.escapeShellArg authTokenFile})"
      printf '{"Authorization":"Bearer %s"}\n' "$token"
    '';
  };
in {
  options.services.dockerMcpGateway = {
    catalogs = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = ["mcp/docker-mcp-catalog:latest"];
      description = ''
        OCI catalogs refreshed on a best-effort basis for interactive profile
        management. Catalog availability does not gate declarative servers.
      '';
    };

    allowedReadOnlyPaths = lib.mkOption {
      type = lib.types.listOf absolutePath;
      default = [];
      description = ''
        Absolute host directory roots that servers may mount read-only. An
        empty list grants no additional host filesystem access.
      '';
    };

    allowedWritablePaths = lib.mkOption {
      type = lib.types.listOf absolutePath;
      default = [];
      description = ''
        Exact absolute host directories that servers may mount read-write. An
        empty list grants no writable host filesystem access.
      '';
    };

    serverReferences = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [];
      description = "Docker MCP catalog, image, or registry server references.";
    };

    serverFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = ''
        Server-entry YAML or JSON files copied into Docker MCP's trusted
        catalog directory before the shared profile is reconciled.
      '';
    };

    toolAllowlist = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nonEmptyListOf lib.types.nonEmptyStr);
      default = {};
      description = "Tools exposed by each server in the shared profile.";
    };
  };

  config = lib.mkIf (serverReferences != []) {
    assertions = [
      {
        assertion = osConfig.virtualisation.docker.enable;
        message = "services.dockerMcpGateway requires Docker Engine.";
      }
    ];

    home.file.".docker/cli-plugins/docker-mcp".source = lib.getExe dockerMcp;
    home.packages = [headersHelper];

    systemd.user.services.docker-mcp-gateway = {
      Unit.Description = "Docker MCP Gateway";

      Service = {
        Environment =
          [
            "HOME=${config.home.homeDirectory}"
            "DOCKER_CONFIG=${config.home.homeDirectory}/.docker"
          ]
          ++ lib.optionals (gateway.allowedReadOnlyPaths != []) [
            "MCP_GATEWAY_DOCKER_BIND_ALLOWED_PATHS=${lib.concatStringsSep ":" gateway.allowedReadOnlyPaths}"
          ]
          ++ lib.optionals (gateway.allowedWritablePaths != []) [
            "MCP_GATEWAY_DOCKER_BIND_ALLOW_WRITABLE_PATHS=${lib.concatStringsSep ":" gateway.allowedWritablePaths}"
          ];
        ExecStartPre = lib.getExe profileReconciler;
        ExecStart = lib.getExe gatewayLauncher;
        Restart = "on-failure";
        RestartSec = "5s";
        UMask = "0077";
      };

      Install.WantedBy = ["default.target"];
    };
  };
}

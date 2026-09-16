# Runs Nix-owned Docker MCP profiles as isolated authenticated HTTP services
# while leaving every other profile available for interactive experimentation.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  gateway = config.services.dockerMcpGateway;
  dockerMcp = pkgs.callPackage ../../../../../packages/docker-mcp.nix {};

  stateRoot = "${config.xdg.stateHome}/docker-mcp-gateway";
  authTokenFile = "${stateRoot}/auth-token";
  catalogRoot = "${config.home.homeDirectory}/.docker/mcp/catalogs";
  absolutePath =
    lib.types.addCheck lib.types.nonEmptyStr (path:
      lib.hasPrefix "/" path && !lib.hasInfix ":" path);
  profileIds = builtins.attrNames gateway.profiles;
  profilePorts = map (id: gateway.profiles.${id}.port) profileIds;

  profileReconciler = pkgs.writeShellApplication {
    name = "docker-mcp-profiles";
    runtimeInputs = [pkgs.coreutils pkgs.openssl];
    text = ''
      umask 077
      catalog_root=${lib.escapeShellArg catalogRoot}
      install -d -m 0700 "$catalog_root/nixos"

      auth_token_file=${lib.escapeShellArg authTokenFile}
      install -d -m 0700 "$(dirname "$auth_token_file")"
      if [ ! -s "$auth_token_file" ]; then
        openssl rand -hex 32 > "$auth_token_file"
      fi
      chmod 0600 "$auth_token_file"

      ${lib.getExe dockerMcp} feature enable profiles >/dev/null

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
          id: let
            profile = gateway.profiles.${id};
            indexes = lib.genList (index: index) (builtins.length profile.serverFiles);
            fileReferences =
              map (
                index: "file://nixos/${id}/${toString index}.yaml"
              )
              indexes;
            serverReferences = profile.serverReferences ++ fileReferences;
          in ''
            profile_dir="$catalog_root/nixos/${id}"
            install -d -m 0700 "$profile_dir"
            ${
              lib.concatMapStringsSep "\n" (
                index: let
                  source = builtins.elemAt profile.serverFiles index;
                in ''
                  install -m 0600 ${lib.escapeShellArg source} "$profile_dir/${toString index}.yaml"
                ''
              )
              indexes
            }

            if ${lib.getExe dockerMcp} profile show ${lib.escapeShellArg id} >/dev/null 2>&1; then
              ${lib.getExe dockerMcp} profile remove ${lib.escapeShellArg id}
            fi

            ${lib.getExe dockerMcp} profile create \
              --id ${lib.escapeShellArg id} \
              --name ${lib.escapeShellArg profile.title} \
              ${lib.concatMapStringsSep " " (reference: "--server ${lib.escapeShellArg reference}") serverReferences}
          ''
        )
        profileIds
      }
    '';
  };

  launchers =
    lib.mapAttrs (
      id: profile:
        pkgs.writeShellApplication {
          name = "docker-mcp-gateway-${id}";
          runtimeInputs = [pkgs.coreutils];
          text = let
            gatewayArguments = [
              "gateway"
              "run"
              "--transport=streaming"
              "--host=127.0.0.1"
              "--port=${toString profile.port}"
              "--block-network=true"
              "--profile=${id}"
            ];
          in ''
            auth_token_file=${lib.escapeShellArg authTokenFile}
            MCP_GATEWAY_AUTH_TOKEN="$(cat "$auth_token_file")"
            export MCP_GATEWAY_AUTH_TOKEN

            exec ${lib.getExe dockerMcp} ${lib.escapeShellArgs gatewayArguments}
          '';
        }
    )
    gateway.profiles;

  gatewayServices =
    lib.mapAttrs' (
      id: profile:
        lib.nameValuePair "docker-mcp-gateway-${id}" {
          Unit = {
            Description = "Docker MCP Gateway (${profile.title})";
            Requires = ["docker-mcp-profiles.service"];
            After = ["docker-mcp-profiles.service"];
          };

          Service = {
            Environment =
              [
                "HOME=${config.home.homeDirectory}"
                "DOCKER_CONFIG=${config.home.homeDirectory}/.docker"
              ]
              ++ lib.mapAttrsToList (name: value: "${name}=${value}") profile.environment
              ++ lib.optionals (gateway.allowedReadOnlyPaths != []) [
                "MCP_GATEWAY_DOCKER_BIND_ALLOWED_PATHS=${lib.concatStringsSep ":" gateway.allowedReadOnlyPaths}"
              ];
            ExecStart = lib.getExe launchers.${id};
            Restart = "on-failure";
            RestartSec = "5s";
            UMask = "0077";
          };

          Install.WantedBy = ["default.target"];
        }
    )
    gateway.profiles;
in {
  options.services.dockerMcpGateway = {
    catalogs = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = ["mcp/docker-mcp-catalog:latest"];
      description = ''
        OCI catalogs refreshed on a best-effort basis for interactive profile
        management. Catalog availability does not gate declarative profiles.
      '';
    };

    allowedReadOnlyPaths = lib.mkOption {
      type = lib.types.listOf absolutePath;
      default = [];
      description = ''
        Absolute host directory roots that profile servers may mount read-only.
        An empty list grants no additional host filesystem access.
      '';
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          title = lib.mkOption {
            type = lib.types.nonEmptyStr;
            default = name;
            description = "Human-readable profile name.";
          };

          port = lib.mkOption {
            type = lib.types.port;
            description = "Loopback port for this profile's Streamable HTTP endpoint.";
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
              catalog directory before the profile is reconciled.
            '';
          };

          environment = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = {};
            description = "Additional non-secret environment variables for this gateway.";
          };
        };
      }));
      default = {};
      description = ''
        Profiles reconciled by Nix. Docker MCP profiles with other identifiers
        remain mutable and can be managed interactively.
      '';
    };
  };

  config = lib.mkIf (gateway.profiles != {}) {
    assertions = [
      {
        assertion = osConfig.virtualisation.docker.enable;
        message = "services.dockerMcpGateway requires Docker Engine.";
      }
      {
        assertion = lib.all (id: builtins.match "[a-z0-9][a-z0-9_-]*" id != null) profileIds;
        message = "Docker MCP profile identifiers must use lowercase letters, numbers, underscores, or hyphens.";
      }
      {
        assertion =
          lib.all (
            id:
              gateway.profiles.${id}.serverReferences
              != []
              || gateway.profiles.${id}.serverFiles != []
          )
          profileIds;
        message = "Every Docker MCP profile must declare at least one server.";
      }
      {
        assertion = builtins.length profilePorts == builtins.length (lib.unique profilePorts);
        message = "Docker MCP profile ports must be unique.";
      }
    ];

    home.file.".docker/cli-plugins/docker-mcp".source = lib.getExe dockerMcp;

    systemd.user.services =
      {
        docker-mcp-profiles = {
          Unit.Description = "Reconcile declarative Docker MCP profiles";

          Service = {
            Type = "oneshot";
            Environment = [
              "HOME=${config.home.homeDirectory}"
              "DOCKER_CONFIG=${config.home.homeDirectory}/.docker"
            ];
            ExecStart = lib.getExe profileReconciler;
            UMask = "0077";
          };
        };
      }
      // gatewayServices;
  };
}

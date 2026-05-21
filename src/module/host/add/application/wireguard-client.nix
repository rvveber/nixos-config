{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.wireguard-client;
  enabledInterfaces = lib.filterAttrs (_: interface: interface.enable) cfg.interfaces;
in {
  options.services.wireguard-client.interfaces = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        enable = lib.mkEnableOption "WireGuard client interface";

        configFile = lib.mkOption {
          type = lib.types.path;
          description = ''
            WireGuard configuration file, typically provided by SOPS from
            a wireguard-server provided client-configuration.
          '';
        };

        configFileDependencies = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = ''
            Optional systemd units that must run before reading configFile.
            Hosts using SOPS-managed files can set this to sops-install-secrets.service.
          '';
        };

        autostart = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to start this WireGuard interface during boot.";
        };
      };
    });
    default = {};
    description = "WireGuard client interfaces managed from secret config files.";
  };

  config = lib.mkIf (enabledInterfaces != {}) {
    environment.systemPackages = [
      pkgs.wireguard-tools
    ];

    networking.wg-quick.interfaces =
      lib.mapAttrs (_: interface: {
        inherit (interface) autostart configFile;
      })
      enabledInterfaces;

    systemd.services =
      lib.mapAttrs' (name: interface:
        lib.nameValuePair "wg-quick-${name}" {
          after = interface.configFileDependencies;
          wants = interface.configFileDependencies;
        })
      enabledInterfaces;
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.urbackup-client;
in {
  options.services.urbackup-client = {
    serverIdentsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Optional file containing trusted UrBackup server identities.
        When set, it is installed as the client's urbackup/server_idents.txt
        before the backend starts.
      '';
    };

    serverIdentsFileDependencies = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Optional systemd units that must run before reading serverIdentsFile.
        Hosts using SOPS-managed files can set this to sops-install-secrets.service.
      '';
    };
  };

  config = {
    # UrBackup client configuration.
    # The client will be installed and enabled, but it won't be configured to connect to any server by default.
    # You can configure trusted server identities per host with `services.urbackup-client.serverIdentsFile`.

    environment.systemPackages = [
      pkgs.urbackup-client
    ];

    systemd.services.urbackup-client = {
      description = "UrBackup client backend";
      after =
        ["network-online.target"]
        ++ lib.optionals (cfg.serverIdentsFile != null) cfg.serverIdentsFileDependencies;
      wants =
        ["network-online.target"]
        ++ lib.optionals (cfg.serverIdentsFile != null) cfg.serverIdentsFileDependencies;
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = "${lib.getExe' pkgs.urbackup-client "urbackupclientbackend"} -t -v info -r server-confirms -l /var/log/urbackupclient.log";
        ExecStartPre = lib.optional (cfg.serverIdentsFile != null) (pkgs.writeShellScript "urbackup-client-install-server-idents" ''
          set -eu
          install -d -m 0700 /var/lib/urbackup-client/urbackup
          install -m 0400 ${cfg.serverIdentsFile} /var/lib/urbackup-client/urbackup/server_idents.txt
        '');
        Restart = "always";
        RestartSec = "10s";
        StateDirectory = "urbackup-client";
        WorkingDirectory = "/var/lib/urbackup-client";
      };
    };

    # Keep client ports closed by default. Open or source-restrict them per host
    # Common UrBackup client ports:
    # - TCP 35621: file backup data
    # - TCP 35623: commands and image backups
    # - UDP 35622/35623: local discovery
  };
}

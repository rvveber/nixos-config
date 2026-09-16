# Scans the running system daily with Syft and Grype; findings trigger a desktop
# notification for each graphical user, including at their next login.
# Syft inventories a read-only closure view with links bounded to that view.
{
  config,
  pkgs,
  ...
}: let
  name = "periodic-security-scan";
  state = "/var/lib/${name}";
  script = ./periodic-security-scan/scan.py;
  scanner = pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = [config.nix.package pkgs.bubblewrap pkgs.syft pkgs.grype pkgs.python3];
    text = ''exec python3 ${script} scan ${state}'';
  };
  notifier = pkgs.writeShellApplication {
    name = "${name}-notify";
    runtimeInputs = [pkgs.python3 pkgs.libnotify];
    text = ''exec python3 ${script} notify ${state}'';
  };
in {
  users.groups.${name} = {};
  users.users.${name} = {
    isSystemUser = true;
    group = name;
  };

  systemd.timers.${name} = {
    description = "Daily running-system vulnerability scan";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  systemd.services.${name} = {
    description = "Inventory the running closure with Syft and scan it with Grype";
    wants = ["network-online.target"];
    after = ["network-online.target"];
    environment = {
      SYFT_CHECK_FOR_APP_UPDATE = "false";
      GRYPE_CHECK_FOR_APP_UPDATE = "false";
      GRYPE_DB_CACHE_DIR = "/var/cache/${name}/grype";
      GRYPE_DB_AUTO_UPDATE = "true";
      GRYPE_DB_REQUIRE_UPDATE_CHECK = "true";
      GRYPE_DB_VALIDATE_AGE = "true";
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    };
    serviceConfig = {
      Type = "oneshot";
      User = name;
      Group = name;
      ExecStart = "${scanner}/bin/${name}";
      StateDirectory = name;
      StateDirectoryMode = "0755";
      CacheDirectory = name;
      CacheDirectoryMode = "0700";
      WorkingDirectory = state;
      UMask = "0022";
      Nice = 19;
      IOSchedulingClass = "idle";
      CPUQuota = "100%";
      MemoryMax = "4G";
      TimeoutStartSec = "2h";
      KillMode = "control-group";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
    };
  };

  systemd.user.services."${name}-notify" = {
    description = "Notify the desktop about the latest system security scan";
    wantedBy = ["graphical-session.target"];
    after = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecCondition = "${pkgs.systemd}/bin/systemctl --user is-active --quiet graphical-session.target";
      ExecStart = "${notifier}/bin/${name}-notify";
      StateDirectory = name;
      StateDirectoryMode = "0700";
      TimeoutStartSec = "30s";
      Restart = "on-failure";
      RestartSec = "1min";
    };
  };
  systemd.user.paths."${name}-notify" = {
    description = "Watch for completed system security scans";
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    pathConfig = {
      PathChanged = state;
      Unit = "${name}-notify.service";
    };
  };
}

# Configures TUXEDO Pulse 14 Gen4 hardware and synchronizes firmware power
# profiles with power-profiles-daemon.
{pkgs, ...}: let
  syncPlatformProfile = pkgs.writeShellApplication {
    name = "tuxedo-platform-profile-sync";
    runtimeInputs = [pkgs.coreutils pkgs.findutils];
    text = ''
      state_file=/var/lib/power-profiles-daemon/state.ini
      profile=

      if [[ -r "$state_file" ]]; then
        while IFS='=' read -r key value; do
          if [[ "$key" == "Profile" ]]; then
            profile="$value"
            break
          fi
        done < "$state_file"
      fi

      case "$profile" in
        power-saver) platform_profile=low-power ;;
        balanced) platform_profile=balanced ;;
        performance) platform_profile=performance ;;
        *) exit 0 ;;
      esac

      profile_path="$(find /sys/devices/platform -path '*/tuxedo_platform_profile/platform_profile' -type f -print -quit)"
      [[ -n "$profile_path" ]] || exit 0

      if [[ "$(< "$profile_path")" != "$platform_profile" ]]; then
        printf '%s\n' "$platform_profile" > "$profile_path"
      fi
    '';
  };
in {
  boot.kernelParams = ["amd_pstate=active"];

  hardware.tuxedo-drivers.enable = true;
  services.fwupd.enable = true;
  services.power-profiles-daemon.enable = true;

  systemd.services.tuxedo-platform-profile-sync = {
    description = "Synchronize the TUXEDO platform and system power profiles";
    after = ["power-profiles-daemon.service"];
    requires = ["power-profiles-daemon.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${syncPlatformProfile}/bin/tuxedo-platform-profile-sync";
    };
  };

  systemd.paths.tuxedo-platform-profile-sync = {
    description = "Watch the system power profile";
    wantedBy = ["multi-user.target"];
    pathConfig.PathChanged = ["/var/lib/power-profiles-daemon/state.ini"];
  };
}

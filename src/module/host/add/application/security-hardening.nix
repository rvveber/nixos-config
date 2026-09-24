# Applies workstation-safe kernel, network, DNS and credential hardening.
{
  lib,
  pkgs,
  ...
}: {
  boot.kernel.sysctl = {
    # Network hardening that is usually transparent for desktop and server use.
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;

    # Kernel self-protection without hiding process lists from normal tools.
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
    "kernel.yama.ptrace_scope" = 1;
  };

  # Needed by browser and Flatpak-style sandboxes; disabling this is worse on a workstation.
  security.allowUserNamespaces = true;

  security.apparmor = {
    enable = true;
    enableCache = true;
  };

  networking = {
    nftables.enable = true;
    resolvconf.enable = false;
    networkmanager.dns = "none";

    firewall = {
      enable = true;
      logRefusedPackets = lib.mkDefault false;
    };
  };

  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
    nameserver ::1
    options edns0 trust-ad
  '';

  services.dnsproxy = {
    enable = true;
    settings = {
      bootstrap = [];
      cache = true;
      dnssec = true;
      fallback = [];
      listen-addrs = [
        "127.0.0.1"
        "::1"
      ];
      listen-ports = [53];
      upstream = [
        "quic://9.9.9.10:853"
        "quic://149.112.112.10:853"
      ];
    };
  };

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  environment.systemPackages = with pkgs; [
    libsecret
    seahorse
  ];
}

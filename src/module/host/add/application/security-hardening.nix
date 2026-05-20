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
    firewall = {
      enable = true;
      logRefusedPackets = lib.mkDefault false;
    };
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      DNSOverTLS = "opportunistic";
      FallbackDNS = [
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
        "1.1.1.1#cloudflare-dns.com"
        "1.0.0.1#cloudflare-dns.com"
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

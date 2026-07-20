_: {
  networking.firewall.allowedTCPPorts = [
    22 # SSH
    25 # SMTP
    80 # HTTP (Traefik ingress + ACME challenge)
    443 # HTTPS (Traefik ingress)
    465 # SMTPS (implicit TLS)
    993 # IMAPS
    4190 # ManageSieve
  ];

  networking.firewall.interfaces.offsitevpn = {
    allowedTCPPorts = [
      35621 # UrBackup file backup data
      35623 # UrBackup commands and image backups
    ];
    allowedUDPPorts = [
      35622 # UrBackup client discovery
    ];
  };

  networking.firewall.interfaces.cni0 = {
    allowedTCPPorts = [
      6443 # Kubernetes API access from pods
      10250 # Kubelet API access from pods (for example metrics-server)
    ];
  };
}

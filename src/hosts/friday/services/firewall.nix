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
}

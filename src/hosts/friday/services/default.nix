{...}: {
  imports = [
    ./firewall.nix
    ./k3s.nix
    ./k8s-secrets-sync.nix
    ./wireguard-client.nix
    ./urbackup-client.nix
    # ./k8s-reapply-manifests.nix
  ];
}

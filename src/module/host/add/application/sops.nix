# Integrates sops-nix with host-key decryption while leaving secret declarations
# and consumer behavior with the host or user that owns them.
{sops-nix, ...}: {
  imports = [
    sops-nix.nixosModules.sops
  ];

  sops.defaultSopsFormat = "yaml";

  # Use the host's SSH key for decryption at runtime
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
}

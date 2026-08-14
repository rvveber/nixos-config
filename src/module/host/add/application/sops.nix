# This module only provides the shared SOPS runtime configuration.
# Scoped secret files, declarations, templates, and consumer behavior belong
# to the host or user that owns them.
{sops-nix, ...}: {
  imports = [
    sops-nix.nixosModules.sops
  ];

  sops.defaultSopsFormat = "yaml";

  # Use the host's SSH key for decryption at runtime
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
}

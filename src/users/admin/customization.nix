{
  config,
  pkgs,
  lib,
  ...
}: let
  username = "admin";
  homeDirectory = "/home/admin";
in {
  users.users.${username} = {
    isNormalUser = true;
    useDefaultShell = true;
    home = homeDirectory;
    description = "Administrator";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpto9262U8wsnRbcj/p95fhhrlj7bMqiLmoOfOfnhG0"
    ];
  };
}

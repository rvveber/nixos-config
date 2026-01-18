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
    # initialHashedPassword = "$6$.WQgq71/Lbgz/jyN$bpNXKqk4M5aBAw6YF5jq3noD0p55OncfsJi9f9RjBBEOtFfTLFO1fJwuG3T.RJkBxVMWNJLnTfZDV0pzVXzTR/";
    # Is the hash for this random initial password (tutorial purposes only):
    # gloomy-yapping-magician-mousiness-opposing-employed-revert-spiritual-tidal
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpto9262U8wsnRbcj/p95fhhrlj7bMqiLmoOfOfnhG0"
    ];
    extraGroups = [ "wheel" "docker" ];
  };
}

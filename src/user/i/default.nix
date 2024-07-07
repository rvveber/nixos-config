# src/user/$username/default.nix - user specific configuration
{
  config,
  pkgs,
  ...
}: {
  users.users.i = {
    isNormalUser = true;
    home = "/home/i";
    description = "Robin Weber";
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [
      thunderbird
    ];
  };
}

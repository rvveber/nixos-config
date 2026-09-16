# Integrates Home Manager into NixOS with shared package and backup policy.
{home-manager, ...}: {
  imports = [
    home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    sharedModules = [
      {
        programs.home-manager.enable = true;
      }
    ];
  };
}

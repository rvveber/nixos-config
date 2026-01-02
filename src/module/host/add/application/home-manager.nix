{
  config,
  pkgs,
  home-manager,
  ...
}: {
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

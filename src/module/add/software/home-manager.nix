{
  config,
  pkgs,
  home-manager,
  ...
}: {
  imports = [
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bak";
    }
  ];
}

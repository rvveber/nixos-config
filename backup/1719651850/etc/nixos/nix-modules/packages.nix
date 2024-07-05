{ pkgs, ... }: 

{
  environment.systemPackages = with pkgs; [
    nixpkgs-fmt
    nil
    nixd
    minecraft
  ];
}

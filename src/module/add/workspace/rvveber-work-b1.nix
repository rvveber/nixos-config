{
  config,
  pkgs,
  lib,
  ...
}: let
  scriptName = "example-script.sh";
in {
  options.exampleModule = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the example module to generate a shell script.";
    };
  };

  config = {
    exampleModule = lib.mkIf config.exampleModule.enable {
      scriptPath = pkgs.writeShellScript scriptName ''
        #!/usr/bin/env bash
        echo "Hello, this is an example script!"
      '';
    };

    environment.systemPackages = lib.mkIf config.exampleModule.enable (with pkgs; [
      bash
      coreutils
    ]);
  };
}

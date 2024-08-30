{lib, ...}: {
  options = {
    generate.script = lib.mkOption {
      type = lib.types.lines;
      default = "echo 'Hello, world!'";
      description = "The script to run";
    };
  };
}

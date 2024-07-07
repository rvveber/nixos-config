This config structure for NixOS aims to be:
- self-explainatory
- minimal
- flake based
- multi-host compatible
- multi-user compatible
- easily universally extendable

It optionally includes home-manager.

***
Don't get discouraged by all the files in the root, they are optional development assisting tools.
What is important for the NixOS configuration, is only the `src` directory.
***

## Quick Start
Make this config structure your own
1. (fork this repository)
2. `git clone <repository-uri>`
3. create configuration for your host - (be sure to have set the hostname in configuration.nix)
```shell
mkdir src/host/$(hostname)
```
4. copy over your host configuration.nix and hardware-configuration.nix 
```shell
cp /etc/nixos/*configuration.nix src/host/$(hostname)
```
5. create `src/host/$(hostname)/default.nix`, that acts as entrypoint
```shell
nano src/host/$(hostname)/default.nix
```
6. paste the following boilerplate and customize to your needs
```nix
{ ... }:
{
    imports = [
        ./hardware-configuration.nix
        ./configuration.nix

        # import (or create) your locale - sets keyboard and timezone stuff
        ../../module/select/locale/de_DE.nix

        # import (or create) hardware features
        ../../module/add/hardware/audio.nix
        ../../module/add/hardware/nvidia.nix

        # (optional) import development module - enables everything to further develop this config
        ../../module/add/software/development.nix
    ];
}
```
7. copy the `user/i` directory to a directory with your username - acts as entrypoint for user configurations
```shell
cp -r src/user/i src/user/$(whoami)
```
8. in the files in it, replace all occurances of the user `i` with your username
9. in `src/flake.nix` add a new nixosConfigurations entry for your hostname and user combination (can be multiple)
```nix
    ...
    nixosConfigurations.<HOSTNAME> = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        ./host/<HOSTNAME>
        ./user/<USERNAME>
      ];
    };
    ...
```
10. Test, that everything is working
```shell
sudo bin/push-and-apply
```
11. Done! You now have a minimal multi-host, multi-user NixOS configuration
***

### Updating
Update all packages, by simply running `bin/update` and apply with `sudo bin/switch`

### Development
You will most likely want expand this configuration, you're in luck, because thats exactly what this repository aims to assist you with. 

If you'd like to enable nix's development features in general, you'll need to add the `module/add/software/development.nix` module to your hosts default.nix.

Then, the various tools to assist development with nix, will be loaded automatically when you enter the directory where you cloned this repository.

- `bin/lint` to check and (optionally) fix static errors



### Future
This repository is ever evolving, so if you have certain requests featurewise, don't hesitate to create issues.
I try to keep it minimal, but i'm also using it for myself, in the future i'll create a second repository
that acts as pure boilerplate and will be even more minimal than now.
This config structure for NixOS aims to be:
- beginner-friendly (imports only - avoids custom nix libraries)
- self-explainatory (heavy use of self-describing file structure and comments)
- easily universally extendable
- flake based (updated regularely)
- multi-host compatible
- multi-user compatible

## Quick Start
Make this config structure your own
1. [Change hostname in configuration.nix](https://letmegooglethat.com/?q=nixos+set+hostname) and [switch the system once](https://nixos.wiki/wiki/Nixos-rebuild)
2. (fork this repository)
3. `git clone <https-repository-url>` and `cd nixos-config`
4. create configuration for your host
```shell
mkdir src/host/$(hostname)
```
5. copy over your host configuration.nix and hardware-configuration.nix 
```shell
cp /etc/nixos/*configuration.nix src/host/$(hostname)
```
6. rename them to better describe their new context (and to fit in this project)
```shell
mv src/host/$(hostname)/hardware-configuration.nix src/host/$(hostname)/hardware.nix \
mv src/host/$(hostname)/configuration.nix src/host/$(hostname)/customization.nix
```
7. create a `src/host/$(hostname)/default.nix`, that acts as entrypoint. 
To keep it simple, copy a default.nix from one of my hosts e.g. `b1kini` and edit as you wish.
```shell
cp src/host/b1kini/default.nix src/host/$(hostname)/default.nix
```
8. copy the `user/i` directory to a directory with the username you'd like to have - acts as entrypoint for user specific configuration
```shell
cp -r src/user/i src/user/yourusername
```
9. in the files in it, replace all occurances of the user `i` with your username
10. in `src/flake.nix` add a new `nixosConfigurations` entry for your hostname and user combination (can be multiple)
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
bin/build
```
11. Make sure to update your users password via root.
12. Done! You now have a minimal NixOS configuration
without complicated overlays and without a lot of custom nix lang functions.
***

### Updating
Update the system by running `bin/update` and `bin/build` afterwards.

### Garbage Collection
Simple. Run `bin/gc`.
Info: This deletes older boot entries too.

### Development
If you enable the development module (optional) - your nix configuration will automatically be statically checked, 
formated, and you will get nix-lang language features.

If you'd like to enable development features in general, you'll need to add the `module/add/software/development.nix` module to your hosts default.nix.

Then, the various tools to assist development with nix, will be loaded automatically when you enter the directory where you cloned this repository.
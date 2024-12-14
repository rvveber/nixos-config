# NixOS KISS config

> It is the perfect config for a NixOS beginner that wants to have a minimal but usable system on multiple machines, with the flexibility to adapt the config for different usecases on *a per machine* *_and_* *per user basis*.

Features
- beginner-friendly (imports only)
- self-explainatory (self-describing file structure) 
- flake based (updated regularely)
- avoids the usage of advanced nix lang features
- avoids the usage of nix libraries
- avoids the usage of overlays
- modular (easily universally extendable)
- opinionated and well thought out 
- based on best-practices
- home-manager included, without beeing handeled specially

## Quick Start
If you just installed NixOS from e.g. the [ISO](https://nixos.org/download/#nix-more):
1. [Change hostname in configuration.nix](https://letmegooglethat.com/?q=nixos+set+hostname) and [switch the system once](https://nixos.wiki/wiki/Nixos-rebuild)
2. (fork this repository)
3. Mkdir the location where you want to manage your system in the future. e.g. `~/nixos` and cd into it.
4. `git clone <fork-url> .`
5. create configuration for your host
```shell
mkdir src/host/$(hostname)
```
6. copy over your host configuration.nix and hardware-configuration.nix 
```shell
cp /etc/nixos/*configuration.nix src/host/$(hostname)
```
7. rename them to better describe their new purpose (and to fit in this project)
```shell
mv src/host/$(hostname)/hardware-configuration.nix src/host/$(hostname)/hardware.nix \
mv src/host/$(hostname)/configuration.nix src/host/$(hostname)/customization.nix
```
8. create a `src/host/$(hostname)/default.nix`, that acts as entrypoint. 
To keep it simple, copy a default.nix from one of my hosts e.g. `b1kini` and edit as you wish.
```shell
cp src/host/b1kini/default.nix src/host/$(hostname)/default.nix
```
9. copy the `user/i` directory to a directory with the username you'd like to have - acts as entrypoint for user specific configuration
```shell
cp -r src/user/i src/user/yourusername
```
10. in the files in it, replace all occurances of the user `i` with your future username
11. in `src/flake.nix` modify/add this `nixosConfigurations` entry for your hostname and user combination (can be multiple)
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
12. Test, that everything is working, user should be created
```shell
bin/build
```
13. Make sure to update your users password via root.
14. Done! You now have a solid and simple NixOS configuration. 
15. Explore the config and you will understand everything else
***

### Updating
Update the system(flake) by running `bin/update` and `bin/build` afterwards.

### Garbage Collection
Simple. Run `bin/gc`.
> Info:<br>This deletes older boot entries!<br>Make sure that your current config/boot-entry is bootable (by rebooting once)

### Development
If you enable the development module (optional) - your nix configuration will automatically be statically checked, 
formatted and you will gain nix lsp.

If you'd like to enable development features in general, you can add the `module/add/software/development.nix` module to your hosts default.nix.

Then, the various tools to assist development with nix, will be loaded automatically when you enter the directory where you cloned this repository.

### Default customizations
> Bare essentials, for freedom of mind and perfomance.
That i use for my daily development work

If you follow the quickstart, copy the config for `b1kini` and `i` (as mentioned). 
You will get:

#### A pre-made frontend config
- Hyprland (preconfigured with bwspm inspired keybinds)
- Beautiful minimalistic Lockscreen
- All UI scripted with AGS exclusively

- Login via bare tty
- Autostart with uwsm
- Automatic lock and suspend when using laptop

- `<super>` opens app launcher (ags)
- `<super> + l` locks the screen (hyprlock)
- `<super> + s` for solid screenshotting (wayland-freeze, grim, satty, magick)

#### A pre-made nvim config
- based on kickstart.nvim
- bun and zig, instead of node and gcc for fastest plugin-installs, -compiles and -runtime

#### A pre-made ZSH config
- powerlevel10k, customization at first startup
- compatible with direnv
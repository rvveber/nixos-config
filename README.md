# NixOS KISS Config

> A simple, minimal, beautiful, and fast NixOS configuration for beginners, adaptable for different use cases on multiple machines.

## What You Will Get
### Sane defaults
- Beginner-friendly (imports only)
- Self-explanatory file structure
- Flake-based (updated regularly)
- Avoids advanced Nix language features, libraries, and overlays
- Modular and easily extendable
- Opinionated and based on best practices
- Includes home-manager without special handling
- Pre-made frontend configuration to kickstart your own

### Pre-made Frontend Config
- [Hyprland](https://hyprland.org/) (Wayland exclusive)
- [Hyprlock](https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/) (Beautiful lockscreen)
- System-wide theming with [stylix](https://github.com/danth/stylix) (pre-configured with clean FutureHUD colors)
- UI scripting with [AGS](https://github.com/Aylur/ags)
- Login via bare TTY with [uwsm](https://github.com/Vladimir-csp/uwsm)
- Automatic lock and suspend for laptops
- Keybindings:
  - `<super>`: Open app launcher (AGS)
  - `<super> + l`: Lock screen (Hyprlock)
  - `<super> + s`: Screenshot (wayland-freeze, grim, satty, magick)

### Pre-made Neovim Config
- Based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
- Includes [bun](https://bun.sh/) and [zig](https://ziglang.org/)

### Pre-made ZSH Config
- [powerlevel10k](https://github.com/romkatv/powerlevel10k)
- Compatible with [direnv](https://direnv.net/)

## Quick Start
1. Install NixOS from the [ISO](https://nixos.org/download/#nix-more).
2. Change hostname in `configuration.nix` and switch the system once.
3. Fork this repository.
4. Create a directory for managing your system, e.g., `~/nixos`, and cd into it.
5. Clone your forked repository:
    ```shell
    git clone <fork-url> .
    ```
6. Create a directory for your host configuration:
    ```shell
    mkdir src/host/$(hostname)
    ```
7. Copy your host configuration files:
    ```shell
    cp /etc/nixos/*configuration.nix src/host/$(hostname)
    ```
8. Rename the configuration files:
    ```shell
    mv src/host/$(hostname)/hardware-configuration.nix src/host/$(hostname)/hardware.nix
    mv src/host/$(hostname)/configuration.nix src/host/$(hostname)/customization.nix
    ```
9. Create an entry point for your host:
    ```shell
    cp src/host/b1kini/default.nix src/host/$(hostname)/default.nix
    ```
10. Copy and customize the user configuration:
    ```shell
    cp -r src/user/i src/user/yourusername
    ```
11. Replace occurrences of `i` with your username in the copied files.
12. Update `src/flake.nix` with your hostname and user combination:
    ```nix
    // ...existing code...
    nixosConfigurations.<HOSTNAME> = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        ./host/<HOSTNAME>
        ./user/<USERNAME>
      ];
    };
    // ...existing code...
    ```
13. Test the configuration:
    ```shell
    bin/build
    ```
14. Update your user's password via root.
15. Explore the configuration to understand further details.

## Updating
To update the system (flake), run:
```shell
bin/update
bin/build
```

## Garbage Collection
To perform garbage collection, run:
```shell
bin/gc
```
> Info:<br>This deletes older boot entries!<br>Make sure that your current config/boot-entry is bootable (by rebooting once)

## Development
If you enable the development module (optional), your Nix configuration will automatically be statically checked, formatted, and you will gain Nix LSP.

To enable development features, add the `module/add/software/development.nix` module to your host's `default.nix`.

The various tools to assist development with Nix will be loaded automatically when you enter the directory where you cloned this repository.
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
- Prefer Home Manager for user apps & dotfiles (still built by Nix); keep `module/host/*` for truly system-wide things (services, drivers, shells, etc.)
- Pre-made frontend configuration to kickstart your own

### Pre-made Frontend Config (rvveber-fhud)
- [Hyprland](https://hyprland.org/) (Wayland exclusive)
- [Hyprlock](https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/) (Beautiful lockscreen)
- System-wide theming with [stylix](https://github.com/danth/stylix) (pre-configured with clean FutureHUD colors)
- UI scripting with [AGS](https://github.com/Aylur/ags)
- Login via bare TTY with [uwsm](https://github.com/Vladimir-csp/uwsm)
- Automatic lock and suspend for laptops
- Keybindings:
  - `super + a`: App launcher
  - `super + l`: Lock screen
  - `super + s`: Screenshot (Instant freeze > Select region > Annotate > Save > Compress to AVIF > Clipboard)

### Pre-made Neovim Config
- Based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
- Uses [bun as fast nodejs replacement](https://bun.sh/) and [zig as fast gcc replacement](https://ziglang.org/)

### Pre-made ZSH Config
- [powerlevel10k](https://github.com/romkatv/powerlevel10k)
- Compatible with [direnv](https://direnv.net/)

## Fresh install
1. Fork this repository.
2. Add a host and user configuration (`src/hosts/yourhostname`, `src/users/yourusername`) - see/copy existing files for reference: 
    - For <u>Desktops</u> i recommend copying the user `i` and the host `b1kini`
    - For <u>Servers</u> i recommend copying the user `rvveber` and the host `friday`

3. You may leave my configurations as is and simply append yours (in `src/flake.nix`). You only activate <u>one</u> of the `nixosConfigurations` there for <u>your machine anyways</u>, so it doesn't matter if multiple are defined - when i update my config in the future - (and i will) - you can sync the fork and keep your own host/user configs intact while still seeing the changes i made for reference, you decide if and when you want to apply them to your own config.
4. Make sure to commit and push your changes to your fork.
5. Start a live ISO NixOS installer instance [Download ISO](https://nixos.org/download/#nix-more) on the target machine.
6. Open a terminal, become root (`sudo -i`) and set your keymap e.g. (`loadkeys de`) for DE
7. You should have internet connectivity, make sure you have.
8. (Optional): Note down the working internet assignment deployed by the live ISO, in case you later need to fix something or want to statically define network in the nixos configuration. (Google/LLM the commands if you don't know how to do this) 
9. View the autodetected hardware-configuration for your machine without filesystem info:
    ```shell
    nixos-generate-config --show-hardware-config --no-filesystems
    ```
    In your fork - edit the content of `src/hosts/yourhostname/hardware.nix` to match the output of the command to make sure its tailored to your hardware.
10. Make sure the user you configure in `src/users/yourusername/customization.nix` has atleast a <u>random</u> [`initialHashedPassword`](https://search.nixos.org/options?channel=unstable&show=users.users.%3Cname%3E.initialHashedPassword&query=users.users.%3Cname%3E) and has `wheel` in [`extraGroups`](https://search.nixos.org/options?channel=unstable&show=users.users.%3Cname%3E.extraGroups&query=users.users.%3Cname%3E), so you can login and administer the system after installation. You can hash a password with 
    ```shell
    openssl passwd -6 long-random-initial-password-that-you-only-need-for-first-login
    ```
    > ### 🚨 If your fork is public (bots can read it)
    > - <b>Don't use your real password.</b> Hashes are guessed/reversed and mapped to passwords in public lists! 
    > - <b>Don't use an existing password.</b> Lists of common password hashes exist and malicious bots are fast!
    > - <b>Note the random password down temporarily.</b> You will need it for first login after installation.
    > - <b>Change your password after first login.</b> I'll remind you in step 14. 
    > - <b>Regarding secrets in general:</b> Never store secrets in plain text [Use encryption or secret management tools](https://wiki.nixos.org/wiki/Comparison_of_secret_managing_schemes) instead. 

    OK. Commit & push the changes.
11. Next we'll use [disko-install](https://github.com/nix-community/disko) to partition, mount and install nixos in a fully declarative way by creating a disko configuration <br>(see `src/hosts/friday/disko.nix` for an example. [More examples here](https://github.com/nix-community/disko/tree/master/example)).<br> After you created/edited and commited/pushed that disko configuration file, on your target machine run:

    ```shell
    git clone <fork-url>
    ```
    ```shell
    cd nixos-config/src 
    ```
    Then run the disko-install command below, that conveniently also installs NixOS. <br>Example below for the host `friday` where the disko config `disko.devices.disk.main.device` is set to `/dev/disk/by-path/virtio-pci-0000:00:10.0`. <br>
    > Change `friday` to your hostname!<br>
    > Change `main /dev/disk/by-path/virtio-pci-0000:00:10.0` to match the disk defined in your disko configuration file!
    > ### 🚨 Obviously this will ERASE ALL DATA on the specified disk!
    ```shell
    nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko/latest#disko-install -- --flake .#friday --disk main /dev/disk/by-path/virtio-pci-0000:00:10.0
    ```
    
12. OK! You should have NixOS installed now.<br> Remove the live ISO and reboot into your new system. 
13. Login with the user you defined in `src/users/yourusername/customization.nix` and the random password you noted down in step 10.
14. 🚨 <b>Update your password manually</b>
    ```shell
    passwd yourusername
    ```
    > The hashed password configured in [`initialHashedPassword`](https://search.nixos.org/options?channel=unstable&show=users.users.%3Cname%3E.initialHashedPassword&query=users.users.%3Cname%3E) is only set when the user is first created, and will not overwrite an existing password when you apply your configuration in the future 🙂<br><br>
    However, it might be wise to remove the line from your user configuration to force yourself to hash a fresh random password next time you re-install from your fork.
    
15. Next we want to define <u>the location</u> from where we will update our system from in the future. 
16. Create a directory for managing your system, e.g., `~/nixos`, and cd into it.
17. Clone your forked repository:
    ```shell
    git clone <fork-url> .
    ```
18. Apply the configuration now (and in the future):
    ```shell
    bin/build
    ```

19. Congratulations, you can now boot into your new NixOS system with your custom configuration and update it from within! 

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

## Secret Management
Secrets are encrypted using [sops-nix](https://github.com/Mic92/sops-nix). Only authorized machines can decrypt them at boot using their SSH Host Key.

**To edit secrets:**
Run `./bin/edit-secrets` (Uses your local machine's SSH key).

**First-time setup (Fork):**
Since you don't have my keys, you must reset the secrets for your machine:
1.  Get your machine's public age key: `nix shell nixpkgs#ssh-to-age -c ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub`
2.  Replace the keys in `src/secrets/.sops.yaml` with your output.
3.  Delete `src/secrets/secrets.yaml` and recreate it: `./bin/edit-secrets` (Add content, save).
4.  Commit and push.

## Development
If you import the development module (optional), your Nix configuration will automatically be statically checked, formatted, and you will gain Nix LSP.

To import development features:
- system-wide (cache substituters / services): `src/module/host/add/application/development.nix`
- per-user tools (git/direnv/dev tools): `src/module/user/add/application/development.nix`

The various tools to assist development with Nix will be loaded automatically when you enter the directory where you cloned this repository.

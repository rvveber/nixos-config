# nixos-config
A beginner-friendly nixos-config.<br>
Feel free to fork, or contribute.

### Scope
This is not just an individual NixOS config.<br>

It is to be considered a best practice starting point for your individual NixOS config on NixOS.

It includes some tiny helper-scripts so you can actively evolve your configuration.<br>

### Important
This repository focuses on providing a utility to evolve a native NixOS system over time, with up-to-date packages through the usage of flakes.

We are not touching<br>
`/etc/nixos/configuration.nix`<br>
`/etc/nixos/hardware-configuration.nix`

Those are your individual config files.
They provide information, such as, which users exist. 

We are not hardcoding values that will definitely be different for your machine. (users, hostnames, hardware, boot etc..)

These values have to be pre-configured by hand, in your configuration.nix, so that we can access them in the flakes.

### Pre-configure

Compare [Misterio77's configuration.nix](https://github.com/Misterio77/nix-starter-configs/blob/main/minimal/nixos/configuration.nix) and your existing `configuration.nix` in `/etc/nixos` to understand how to set the required values.

Then, set the following required values in your existing `/etc/nixos/configuration.nix` file.

- users.users
- networking.hostName
- experimental-features = "nix-command flakes"

### Use
At this point you should have NixOS installed
and pre-configured `/etc/nixos/configuration.nix` to include the required values mentioned above.

Now you can
1. Activate your pre-configuration with `sudo nixos-rebuild switch`
2. Clone this repository to a project directory, eg. `/p/nixos-config`
3. Navigate to it
4. (optional) Update to the latest packages `./update`
5. Execute `./push-and-apply` - pushes  contents of `nixos/` to `/etc/nixos` and switches the system to the new configuration.

***
## In the future

In the future, just evolve your configuration in an IDE at eg. `/p/nixos-config` and `sudo ./push-and-apply` it.

Don't touch `/etc/nixos/configuration.nix` or `/etc/nixos/hardware-configuration.nix`, except when you want to introduce new variables for your flakes to access, or fundamentally change hardware/drives/boot etc.

### Inspiration from
https://drakerossman.com/blog/how-to-convert-default-nixos-to-nixos-with-flakes
https://github.com/vimjoyer/flake-starter-config
https://github.com/Misterio77/nix-starter-configs
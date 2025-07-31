- [x] Find out, what is more scalable, system wide configuration, or home-manager and if we need to use one or the other, or if we can use both

This repository is primarily focused on nixos.
Thats because the flake is designed to be used with nixos.

home-manager is a tool to manage user specific configuration and it uses nix to do so, but it is not a part of the nixos system configuration.

We are currently making it a part of the nixos configuration implicitly (through importing in modules that require it to configure additional things, that can only be configured on user level, like stylix.)

All our "modules" are nixos modules, they are not home-manager modules, and yes there is a difference.
In fact we do not have a single home-manager module.
Every module is a nixos module, which can define home-manager configuration, but it is not a home-manager module itself. 

Should we change that?
What benefits would we get from that?

If we added home-manager modules, we would need to rename "modules" to "nixos-modules" or something like that, because it would be confusing to have both nixos modules and home-manager modules in the same directory.

If we want to use home-manager modules, we would need to add a new directory for them, like "hm-modules" or something like that.

There would probably just be a few of them, and usually you don't decide against them.
If you want the full experience with stylix, you need to use home-manager configurations, but that we do within nixos modules, so it is not a problem.

Do we really need to separate these configurations into their own nix modules?

We need to think about combining users more carefully.
If we talk about a multi-user system, than we also need to think about permissions, and how the user with less permissions chooses their configuration.

Right now you need to be root to build the configuration, inclusive of the home-manager configuration for you user.

Technically you wouldn't need to be root to build the home-manager configuration, but you need to be root to build the nixos configuration, and the home-manager configuration is a part of that.

Can we separate the home-manager configuration from the nixos configuration in such a way that it is still declarative, in the same repository, and can be built by a user without root permissions?

What really needs to be on the system level?
Does stylix need to be on the system level?

Well for once, how would the system be styled when booting, if the user configuration is not available yet?













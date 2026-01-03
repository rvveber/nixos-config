We need to think about combining users more carefully.
If we talk about a multi-user system, than we also need to think about permissions, and how the user with less permissions chooses their configuration.

Right now you need to be root to build the configuration, inclusive of the home-manager configuration for you user.

Technically you wouldn't need to be root to build the home-manager configuration, but you need to be root to build the nixos configuration, and the home-manager configuration is a part of that.

Can we separate the home-manager configuration from the nixos configuration in such a way that it is still declarative, in the same repository, and can be built by a user without root permissions?
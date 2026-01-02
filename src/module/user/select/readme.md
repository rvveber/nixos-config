All modules in the `module/user/select` directory are optional and GLOBALLY exclusive.
Do NOT combine these with modules of the same type.
The "type" of the module is derived from its parent directories.
e.g.
`module/user/select/customization/application/neovim/rvveber-nvim` is of type `customization/application/neovim`.
only select one `customization/application/neovim`.

Import them in
`users/<user>/customization.nix` via `home-manager.users.<user>.imports`

Note: `home-manager.sharedModules` applies to all HM users. `home-manager.users.<user>.imports` keeps it user-scoped.

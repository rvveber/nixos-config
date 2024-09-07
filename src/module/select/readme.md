All modules in the `modules/select` directory are optional. 
Do not combine these with other modules of the same type.
The type of the module is derived from its parent directories.
e.g. 
`modules/select/locale/de_DE` is of type `locale`.
`modules/select/customization/application/neovim/rvveber-nvim` is of type `customization/application/neovim`.

Import them in
`host/<host>/default.nix`
or 
`user/<user>/default.nix`
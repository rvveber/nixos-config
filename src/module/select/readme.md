All modules in the `modules/select` directory are optional and GLOBALLY exclusive. 
Do NOT combine these with modules of the same type.
The "type" of the module is derived from its parent directories.
e.g. 
`modules/select/locale/de_DE` is of type `locale`.
only select one `locale`.
`modules/select/customization/application/neovim/rvveber-nvim` is of type `customization/application/neovim`.
only select one `customization/application/neovim`.

Import them in
`host/<host>/default.nix`
or 
`user/<user>/default.nix`
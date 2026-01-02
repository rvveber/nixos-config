All modules in `module/host/select` are NixOS (system) modules and are optional and GLOBALLY exclusive.
Do NOT combine these with modules of the same type.
The "type" of the module is derived from its parent directories.
e.g. 
`module/host/select/locale/de_DE` is of type `locale`.
only select one `locale`.
`module/host/select/application/shell/zsh` is of type `application/shell`.
only select one `application/shell`.

Use `module/host/*` when it must be system-wide. Prefer `module/user/*` for user applications and dotfiles (Home Manager still builds packages via Nix).

Import them from:
- `hosts/<host>/default.nix`, and/or
- `users/<user>/default.nix` (still system-level config in this repo)

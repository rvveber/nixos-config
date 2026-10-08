This category owns shared AI configuration and individually selectable MCP
servers. Import its modules through `home-manager.users.<user>.imports`
in `users/<user>/customization.nix`.

Each `mcp-*.nix` module imports `../application/docker-mcp-gateway.nix` and
registers its server, filesystem access, and tool selection with that gateway.
Import the desired server modules; Nix deduplicates their shared gateway import.
Application modules, including OpenCode and the gateway, live under
`../application/`.

`codex-to-api.nix` is deprecated and emits a warning when imported. It remains
available for existing configurations.

Personal instructions shared across AI clients belong in
`module/user/select/customization/ai/<profile>.nix`. The maintained prompt can be
inline in that module and supplied to clients through their native instruction
files. The user composition selects the module with a plain import.

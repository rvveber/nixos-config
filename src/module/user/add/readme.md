All files in the `module/user/add` directory are optional and compatible with each other.
Home Manager still uses Nix to build/install packages, but applies configuration per-user.

Import them in
`users/<user>/customization.nix` via `home-manager.users.<user>.imports`

Operational documentation:

- [Shared MCP gateway](application/mcp-gateway.md)

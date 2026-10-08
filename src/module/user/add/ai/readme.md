This category owns per-user AI runtimes, compatibility services, and shared MCP
infrastructure. Import its modules through `home-manager.users.<user>.imports`
in `users/<user>/customization.nix`.

`docker-mcp-gateway.nix` runs the shared MCP endpoint. Each module under `mcp/`
registers its server, filesystem access, and tool selection with that gateway.
Import the gateway alongside the desired server modules.

Personal instructions shared across AI clients belong in
`module/user/select/customization/ai/<profile>.nix`. The maintained prompt can be
inline in that module and supplied to clients through their native instruction
files. The user composition selects the module with a plain import.

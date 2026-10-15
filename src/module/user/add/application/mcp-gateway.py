"""Expose Nix-declared stdio MCP servers through one authenticated endpoint."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import anyio
from fastmcp import FastMCP
from fastmcp.mcp_config import MCPConfig, MCPServerTypes
from fastmcp.server.auth import StaticTokenVerifier
from fastmcp.server.dependencies import get_context
from fastmcp.server.providers.proxy import FastMCPProxy, StatefulProxyClient


class SessionClientPool:
    """Keep one isolated backend process for each incoming MCP session."""

    def __init__(self, server: MCPServerTypes) -> None:
        self.server = server
        self.clients: dict[Any, StatefulProxyClient[Any]] = {}

    def __call__(self) -> StatefulProxyClient[Any]:
        session = get_context().session
        client = self.clients.get(session)
        if client is not None:
            return client

        # A fresh transport matters for stdio: sharing it would also share the
        # backend MCP session and break stateful servers such as REA.
        client = StatefulProxyClient(self.server.to_transport())
        self.clients[session] = client

        async def close_client() -> None:
            self.clients.pop(session, None)
            with anyio.CancelScope(shield=True):
                await client.close()

        session._exit_stack.push_async_callback(close_client)
        return client


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--token-file", required=True, type=Path)
    parser.add_argument("--port", required=True, type=int)
    return parser.parse_args()


def main() -> None:
    arguments = parse_arguments()
    configuration = json.loads(arguments.config.read_text(encoding="utf-8"))
    token = arguments.token_file.read_text(encoding="utf-8").strip()
    if not token:
        raise ValueError("The gateway authentication token is empty")

    servers = MCPConfig.from_dict({"mcpServers": configuration["servers"]}).mcpServers
    gateway = FastMCP(
        "Nix MCP Gateway",
        auth=StaticTokenVerifier(tokens={token: {"client_id": "local", "scopes": []}}),
    )

    for name, server in servers.items():
        proxy = FastMCPProxy(
            name=name,
            client_factory=SessionClientPool(server),
            provider_error_strategy="raise",
        )
        tools = configuration["toolAllowlists"].get(name)
        if tools is not None:
            proxy.disable(components={"tool"})
            proxy.enable(names=set(tools), components={"tool"})
        gateway.mount(proxy, namespace=name)

    gateway.run(
        transport="http",
        host="127.0.0.1",
        port=arguments.port,
        stateless_http=False,
        show_banner=False,
    )


if __name__ == "__main__":
    main()

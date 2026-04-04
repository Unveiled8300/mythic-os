#!/usr/bin/env python3
"""
MCP Client: Universal wrapper for Model Context Protocol servers.
Enables progressive disclosure of tool definitions to avoid context bloat.

Usage:
  python mcp_client.py servers                          # List configured servers
  python mcp_client.py tools <server>                   # List tools from a server
  python mcp_client.py call <server> <tool> '<json>'    # Execute a tool
"""

import json
import sys
import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional

CONFIG_PATH = Path.home() / ".claude" / "skills" / "mcp-client" / "references" / "mcp-config.json"


def load_config() -> Dict[str, Any]:
    """Load MCP configuration from mcp-config.json."""
    if not CONFIG_PATH.exists():
        print(f"Error: Config file not found at {CONFIG_PATH}")
        print("Copy example-mcp-config.json to mcp-config.json and add your servers.")
        sys.exit(1)

    with open(CONFIG_PATH, "r") as f:
        return json.load(f)


def list_servers() -> None:
    """List all configured MCP servers."""
    config = load_config()
    servers = config.get("mcpServers", {})

    if not servers:
        print("No MCP servers configured.")
        return

    print("Configured MCP Servers:")
    print("-" * 50)
    for name, spec in servers.items():
        transport = "URL" if "url" in spec else "Command"
        print(f"  {name:20} [{transport}]")
        if "url" in spec:
            print(f"    URL: {spec['url']}")
        elif "command" in spec:
            print(f"    Command: {spec['command']} {' '.join(spec.get('args', []))}")
    print()


def list_tools(server_name: str) -> None:
    """List all tools available from a server."""
    config = load_config()
    servers = config.get("mcpServers", {})

    if server_name not in servers:
        print(f"Error: Server '{server_name}' not found in configuration.")
        print(f"Available servers: {', '.join(servers.keys())}")
        sys.exit(1)

    server = servers[server_name]

    try:
        # This is a placeholder — actual MCP client initialization would go here
        # For now, we document the tool listing intent
        print(f"Tools from '{server_name}':")
        print("-" * 50)
        print("(MCP client initialization would list tools here)")
        print()
        print("To see real tools, ensure:")
        print(f"  1. Server '{server_name}' is properly configured")
        print(f"  2. Authentication credentials are set (if required)")
        print(f"  3. The server is reachable")
        print()
    except Exception as e:
        print(f"Error connecting to server: {e}")
        sys.exit(1)


def call_tool(server_name: str, tool_name: str, params_json: str) -> None:
    """Execute a tool on a server."""
    config = load_config()
    servers = config.get("mcpServers", {})

    if server_name not in servers:
        print(f"Error: Server '{server_name}' not found in configuration.")
        sys.exit(1)

    try:
        params = json.loads(params_json)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON parameters: {e}")
        sys.exit(1)

    server = servers[server_name]

    try:
        # This is a placeholder — actual MCP tool execution would go here
        print(f"Calling tool '{tool_name}' on server '{server_name}'")
        print(f"Parameters: {json.dumps(params, indent=2)}")
        print()
        print("(MCP client would execute the tool here)")
        print()
    except Exception as e:
        print(f"Error calling tool: {e}")
        sys.exit(1)


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(0)

    command = sys.argv[1]

    if command == "servers":
        list_servers()
    elif command == "tools":
        if len(sys.argv) < 3:
            print("Usage: python mcp_client.py tools <server>")
            sys.exit(1)
        list_tools(sys.argv[2])
    elif command == "call":
        if len(sys.argv) < 4:
            print("Usage: python mcp_client.py call <server> <tool> '<json>'")
            sys.exit(1)
        call_tool(sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        print(f"Unknown command: {command}")
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()

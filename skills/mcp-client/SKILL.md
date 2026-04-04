---
name: mcp-client
description: Universal MCP client for connecting to external MCP servers with progressive disclosure - tool schemas load on-demand instead of bloating your context window
triggers:
  - "connect to Zapier"
  - "use MCP server"
  - "list MCP tools"
  - "call Zapier action"
  - "use sequential thinking"
---

# MCP Client

Connect Claude Code to external MCP servers (Zapier, GitHub, Sequential Thinking, etc.) with progressive disclosure - tool schemas load on-demand instead of bloating your context window.

## Core Philosophy

MCP servers expose thousands of tokens worth of tool definitions. This skill wraps them as a lightweight client, loading only what you need when you need it.

## Setup: Create Your Config

**Step 1:** Copy the example config to create your own:

```bash
cp .claude/skills/mcp-client/references/example-mcp-config.json \
   .claude/skills/mcp-client/references/mcp-config.json
```

**Step 2:** Edit `mcp-config.json` with your API keys and servers.

The config format is identical to Claude Desktop's MCP config:

```json
{
  "mcpServers": {
    "zapier": {
      "url": "https://mcp.zapier.com/api/v1/connect",
      "api_key": "YOUR_API_KEY_HERE"
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

**Transport types:**
- `url` + `api_key` → Remote server with Bearer auth (Zapier)
- `command` + `args` → Local stdio server (npx, python, docker)
- `url` ending in `/sse` → SSE transport
- `url` ending in `/mcp` → Streamable HTTP

## Available Commands

```bash
# List configured servers
python .claude/skills/mcp-client/scripts/mcp_client.py servers

# List tools from a server (with full schemas)
python .claude/skills/mcp-client/scripts/mcp_client.py tools zapier

# Call a tool
python .claude/skills/mcp-client/scripts/mcp_client.py call zapier <tool_name> '{"param": "value"}'
```

## Document Tool Gotchas in CLAUDE.md

**Important:** After setting up MCP servers, test each tool and document any quirks. This saves time on future calls.

Add a section to your project's `CLAUDE.md` - example:

```markdown
## MCP Tool Notes

### Zapier
- `send_gmail_email`: The `to` field must be a single email, not an array
- `create_notion_page`: Requires `database_id`, not `page_id`
- Rate limit: 2 Zapier tasks per MCP call

### Sequential Thinking
- Always set `nextThoughtNeeded: true` until final thought
- `totalThoughts` is advisory, can be adjusted mid-process
```

**Workflow:**
1. Connect a new MCP server
2. Ask Claude: "List all tools from [server] and test each one with sample inputs"
3. Document any failures, required formats, or gotchas in CLAUDE.md
4. Claude will reference these notes on future calls

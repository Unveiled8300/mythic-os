# MCP Server Quirks & Gotchas

This file documents non-obvious behavior, rate limits, and gotchas for each MCP server in your configuration.
Update this as you discover edge cases — it saves time on future calls.

---

## Template: How to Document a Server

```markdown
### [Server Name]

**Authentication**
- Token location: [env var name or config field]
- Expiration: [does token expire? how often?]
- Reauth procedure: [how to refresh if it fails]

**Rate Limits**
- Requests per minute: [N] (or "none observed")
- Per-user limits: [yes/no] — [details]
- Backoff strategy: [exponential, fixed, etc.]

**Known Quirks**
- [Tool name]: [what's unexpected] — [workaround if known]
- [Tool name]: [what's unexpected] — [workaround if known]

**Best Practices**
- Always [thing to do]
- Never [thing to avoid]
- For [scenario], use [approach]

**Example Calls**
\`\`\`bash
# Working example
python mcp_client.py call [server] [tool] '{...}'
\`\`\`
```

---

## Zapier

**Status:** [Not yet documented — test tools and fill in]

---

## Sequential Thinking

**Status:** [Not yet documented — test tools and fill in]

---

## GitHub

**Status:** [Not yet documented — test tools and fill in]

---

## Filesystem

**Status:** [Not yet documented — test tools and fill in]

---

## Adding a New Server

When you add a new MCP server to `mcp-config.json`:

1. Test the connection: `python mcp_client.py tools [server-name]`
2. List available tools for that server
3. Create a test call for at least one tool
4. Document any surprises, auth gotchas, or rate limits here
5. Note whether the tool works as documented or has unexpected behavior

This prevents silent failures and saves debugging time on future sessions.

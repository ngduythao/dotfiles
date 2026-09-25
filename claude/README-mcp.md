# MCP servers

Added per project, not in `settings.json`, because they need credentials.
`claude mcp add` stores a server in `~/.claude.json` for the current project (the default local scope), outside git.
`--scope project` writes a shared `.mcp.json` instead; reference secrets there as `${VAR}`, never literally.
`/mcp` shows what is connected.

Postgres, with a read-only database user:

```bash
claude mcp add --transport stdio db -- npx -y @bytebase/dbhub --dsn "postgresql://readonly:pass@localhost:5432/orders"
```

GitHub, with a fine-grained token limited to the repos and permissions needed:

```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer $GITHUB_PAT"
```

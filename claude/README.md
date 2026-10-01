# Claude Code setup

User-level Claude Code config: `claude/.claude/` is stowed into `~/.claude/`, so it applies in every project on every machine that ran `bootstrap.sh`.
This page says what each piece does, why it exists, and how to show it in a walkthrough.

## What's here

| Piece | Path in `claude/.claude/` | Purpose |
| --- | --- | --- |
| Global instructions | `CLAUDE.md`, `RTK.md` | Loaded in every session |
| Settings | `settings.json` | Hooks, permissions, plugins, status line (committed, public) |
| Hooks | `hooks/` | Guardrails the harness enforces |
| Skills | `skills/` | Workflows invoked as `/<name>` |
| Subagents | `agents/` | Scoped workers that return a summary |
| Status line | `statusline.sh` | Model, effort, context, 5h/7d limits, folder |

Also in `claude/`, not stowed (stow skips `README*`): [`README-mcp.md`](./README-mcp.md) for MCP servers.

Secrets never live here: `settings.local.json`, `.mcp.json`, `.credentials.json` and `.env*` are gitignored.

## Hooks: guardrails outside the model

Hooks are shell commands Claude Code runs on events, outside the model; exit 2 from a `PreToolUse` hook cancels the tool call.
I don't trust prompt-level instructions for safety-critical rules, so those rules live here.

Both hooks run on `PreToolUse` × `Bash`:

- `rtk hook claude` rewrites commands through `rtk` to shorten their output (see `RTK.md`).
- `hooks/block-destructive-git.sh` refuses destructive git commands, and Claude is told to ask me to run them:

| Blocked | Why |
| --- | --- |
| `push --force`, `push -f`, `push --force-with-lease` | Rewrites shared history |
| `reset --hard`, `checkout -- .`, `restore .` | Discards uncommitted work |
| `clean` with `-f` | Deletes untracked files |
| `branch -D` | Force-deletes a branch |
| `commit --amend` | Rewrites the previous commit |
| `--no-verify`, `--no-gpg-sign` | Skips pre-commit hooks or signing |
| `reflog expire` | Makes recovery impossible |

```bash
echo '{"tool_input":{"command":"git push --force"}}' | bash ~/.claude/hooks/block-destructive-git.sh; echo "exit=$?"
# Blocked: destructive git operation detected (force push). Ask the user to run it manually.
# exit=2
```

It matches the command text, so a command that only mentions a pattern (an `echo "git reset --hard"`) is blocked too; that false positive is accepted.

## Skills: codified workflows

| Skill | Does |
| --- | --- |
| `/pr-description` | Drafts a PR description (Summary, Why, Notes for reviewer, Test plan) from the branch diff against main |
| `/security-scan` | Looks for reachable security risks in a chosen part of the code |

Each is `skills/<name>/SKILL.md`: frontmatter with a `description`, and a body Claude follows.
A skill earns its place when it holds what the model cannot know: my decisions, a repo's facts, a script, a fixed output format. Generic "how to do X well" guidance is left to the model.
Why codify them: the same shape every time, and the rules keep the model out of filler such as "improved code quality".
Personal skills sit in the same folder but are gitignored, so they are neither published nor installed on a new machine.

## Subagents: context hygiene

`agents/security-reviewer.md` runs a scoped security review and returns evidence-backed findings without editing code.
Claude Code also ships `Explore`, `Plan` and `general-purpose`.
Delegating large searches or parallel investigations keeps raw file content out of the main context; only the summary comes back.

## Plugins

Declared in `settings.json` and installed on a new machine by `bootstrap.sh`:

- Trail of Bits: `property-based-testing`
- Anthropic: `claude-code-setup`, which recommends hooks, skills and MCP servers for a repo

## MCP servers

Added per project with `claude mcp add`, not in `settings.json`, because they need credentials; see [`README-mcp.md`](./README-mcp.md) (Postgres, GitHub).

## Adding more

- **Hook**: put the script in `hooks/` and wire it in `settings.json` under its event (`PreToolUse`, `PostToolUse`, `Stop`, ...). `hooks/` is linked as a whole directory, so no restow.
- **Skill or subagent**: create `skills/<name>/SKILL.md` or `agents/<name>.md`, then `stow --restow claude` so the new entry is linked. Test with `/<name>`.
- **Plugin**: `claude plugin install <plugin>@<marketplace>` (or `/plugin`); it is written to `settings.json`, so the next `bootstrap.sh` installs it.
- **MCP server**: see `README-mcp.md`.

## Walkthrough cheatsheet

| Question | Show |
| --- | --- |
| "What hooks do you use?" | `cat ~/.claude/settings.json`, then `hooks/` |
| "How do you stop the agent from breaking things?" | The demo command above: exit 2 and the message |
| "Workflows you've codified?" | `cat ~/.claude/skills/pr-description/SKILL.md` |
| "External systems?" | `README-mcp.md` |
| "When does the agent fail?" | Hallucination: the compiler catches it. Confidently wrong: demand `file:line` evidence. Scope creep: the plan is approved before any code, and the agent stays inside it. Destructive: the hook blocks it. |

## Limits

- Nothing here runs unless I start Claude Code; there is no auto-deploy.
- Hooks stop obvious foot-guns; a person still reviews every diff.
- Hook events, skill layout and MCP config change as Claude Code evolves; check the official docs before quoting this.

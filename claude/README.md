# Claude Code setup

What's wired up in `~/.claude/` (stowed from `claude/.claude/`), why each piece exists, and how to demo it during a walkthrough. Everything here is user-level, so it applies in every project on every machine that ran `bootstrap.sh`.

## Layout

```
claude/
├── README.md                        ← you are here (stow skips README*)
├── README-mcp.md                    ← guide for adding MCP servers (per project)
└── .claude/                         ← linked into ~/.claude/
    ├── CLAUDE.md, RTK.md            ← global instructions
    ├── settings.json                ← hooks, permissions, plugins (committed, public)
    ├── statusline.sh
    ├── hooks/
    │   └── block-destructive-git.sh ← PreToolUse: refuse destructive git ops
    ├── agents/
    │   └── security-reviewer.md
    └── skills/
        ├── code-review/             ← /code-review (financial + Solidity checklist)
        ├── pr-description/          ← /pr-description
        ├── security-scan/
        └── systematic-debugging/
```

Plugins (Trail of Bits `building-secure-contracts`, `property-based-testing`) are declared in
`settings.json` and installed by `bootstrap.sh`. Secrets never go here: `settings.local.json`,
`.mcp.json`, `.credentials.json` and `.env*` are gitignored.

## 1. Hooks — deterministic guardrails

Hooks are shell commands the **harness** (Claude Code itself) runs on events. They execute outside the model — exit code 2 from a `PreToolUse` hook aborts the tool call before it runs. Why this matters: I don't trust prompt-level instructions for safety-critical rules; the harness layer is deterministic.

`rtk hook claude` (`PreToolUse` × `Bash`) rewrites commands through `rtk` to shorten their output; see `RTK.md`.

### `block-destructive-git.sh` — `PreToolUse` × `Bash`

Inspects every bash command Claude is about to run. Pattern-matches against destructive git operations:

| Pattern | Reason blocked |
|---------|----------------|
| `push --force` / `push -f` | Force push rewrites shared history |
| `push --force-with-lease` | Even with lease — manual confirm |
| `reset --hard` | Discards uncommitted changes |
| `branch -D` | Force-delete branch |
| `clean -fd` | Deletes untracked files |
| `checkout -- .` / `restore .` | Discards working tree |
| `commit --amend` | Rewrites the previous commit |
| `--no-verify` | Skips pre-commit hooks |
| `--no-gpg-sign` | Skips commit signing |
| `reflog expire` | Makes recovery impossible |

On match: exit 2, stderr explains why. Claude sees the message and stops.

**Demo it:**

```bash
echo '{"tool_input":{"command":"git push --force"}}' \
  | bash ~/.claude/hooks/block-destructive-git.sh ; echo "exit=$?"
# stderr: Blocked: destructive git operation detected...
# exit=2
```

**Caveat**: the hook matches the literal bash command string. Running a test command that *mentions* one of these patterns in an echo will also be blocked — false positive, but the conservative behavior is correct for safety.

## 2. Skills — codified workflow

Slash commands defined in `~/.claude/skills/<name>/SKILL.md`. Invoke with `/<name>` in a Claude Code session. Internally: markdown file with optional frontmatter; body is the instruction Claude follows. `$ARGUMENTS` captures whatever the user typed after the command.

### `/pr-description`

Reads `git log` + `git diff` against `main` (or master/develop, whichever exists). Drafts a structured PR description with **Summary / Why / Notes for reviewer / Test plan** sections, output as a fenced code block ready to paste into GitHub.

Why I codified this: same shape every PR, removes manual templating, and the model can't drift into "improved code quality" filler because the skill rules it out explicitly.

### `/code-review`

Applies a financial-grade checklist (money handling, transaction boundaries, idempotency, concurrency, audit trail, security, observability, Solidity and on-chain integration) to either the current branch diff or a path passed as `$ARGUMENTS`. Each finding gets:

- Severity tag (HIGH / MEDIUM / LOW)
- `file:line` evidence
- What can go wrong in production
- Concrete fix

Ends with strong points, an overall grade and quick wins.

Why I codified this: I tend to forget the same dimensions when reviewing manually. Encoding the checklist removes that bias.

## 3. Subagents — context hygiene

`agents/security-reviewer.md` is the one custom subagent. Claude Code also ships built-in subagents (`Explore`, `Plan`, `general-purpose`). The pattern: when exploring large code or running parallel investigations, the main agent dispatches subagents with restricted scope; each returns a short summary instead of pulling raw file content into the main context window.

This is an *interaction pattern*, not a file in `.claude/`. Worth knowing the pattern exists, especially when prompts get long.

## 4. MCP servers

See [`README-mcp.md`](./README-mcp.md). Not in `settings.json` because they need credentials: add them per project with `claude mcp add` (Postgres, GitHub).

## Demo cheatsheet

| Interviewer question | What to show |
|----------------------|--------------|
| "What hooks do you use?" | `cat ~/.claude/settings.json` → walk through `hooks/` |
| "How do you stop the agent from breaking things?" | Run the demo command above; show exit 2 + message |
| "Workflows you've codified?" | `cat ~/.claude/skills/code-review/SKILL.md` |
| "External systems integration?" | Walk through `README-mcp.md` |
| "When does the agent fail?" | Hallucination → compiler catches. Confidently wrong → demand `file:line` evidence. Scope creep → strict prompt + diff size budget. Destructive → hook blocks. |

## Adding more

- **New hook**: drop the script in `claude/.claude/hooks/`, wire it in `settings.json` under the relevant event (`PreToolUse`, `PostToolUse`, `Stop`, etc.).
- **New skill**: create `claude/.claude/skills/<name>/SKILL.md` with `description:` in frontmatter, then `stow --restow claude` so the new folder is linked. Test by typing `/<name>`.
- **New MCP server**: see `README-mcp.md`.
- **New plugin**: install it once with `/plugin`; Claude Code writes it to `settings.json`, and `bootstrap.sh` installs it on the next machine.

## What this is NOT

- Auto-deploy. Nothing in `~/.claude/` runs without a human invoking Claude Code.
- A replacement for code review. Hooks block obvious foot-guns; diffs still get reviewed by a person.
- Permanent. Hook event names, skill directory layout, and MCP config format will shift as Claude Code evolves. Re-check the official docs before quoting any of this verbatim.

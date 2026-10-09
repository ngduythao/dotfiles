# Claude Code setup

User-level Claude Code config: `claude/.claude/` is stowed into `~/.claude/`, so it applies in every project on every machine that ran `bootstrap.sh`.
Only what every project needs lives there. Skills and subagents are kept in `claude-library/` and copied into the repos that use them.
This page says what each piece does, why it exists, and how to show it in a walkthrough.

## What's here

| Piece | Path in `claude/.claude/` | Purpose |
| --- | --- | --- |
| Global instructions | `CLAUDE.md`, `RTK.md` | Loaded in every session |
| Settings | `settings.json` | Hooks, permissions, plugins, status line (committed, public) |
| Hooks | `hooks/` | Guardrails the harness enforces |
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

## Skills and subagents: per repo, not global

`claude-library/` at the root of this repo is not a stow package, so nothing in it reaches `~/.claude/`.
A repo that needs a skill gets its own copy in `.claude/skills/<name>/` (a subagent in `.claude/agents/`), trimmed to what that repo uses and committed there.

Why not global: every installed skill costs context in every session of every project, a global skill cannot name a repo's verify command or reviewer, and a teammate who clones the repo gets nothing that lives only in my home directory.

```bash
mkdir -p .claude/skills && cp -R ~/Desktop/dotfiles/claude-library/skills/diagnose .claude/skills/
```

After copying, cut what the repo does not need and replace generic wording with the repo's own (verify command, where plans live, reviewer agent). The copy belongs to the repo from then on; a change worth keeping for other repos is carried back here by hand.

| Skill | Does |
| --- | --- |
| `/pr-description` | Drafts a PR description (Summary, Why, Notes for reviewer, Risk, Evidence, Test plan) from the branch diff against the base branch (main, master or develop) |
| `/security-scan` | Looks for reachable security risks in a chosen part of the code |
| `/diagnose` | Finds a bug's cause before fixing it: a command that fails on the bug, shrink it, ranked hypotheses, then a fix with a regression test. The loop follows `diagnosing-bugs` in [mattpocock/skills](https://github.com/mattpocock/skills) (MIT), rewritten with gates |

Each is `claude-library/skills/<name>/SKILL.md`: frontmatter with a `description`, and a body Claude follows.
A skill earns its place when it holds what the model cannot know: my decisions, a repo's facts, a script, a fixed output format. Generic "how to do X well" guidance is left to the model.
Why codify them: the same shape every time, and the rules keep the model out of filler such as "improved code quality".
Personal skills (`feature`, `fintech-review`) sit in the same folder but are gitignored, so they are not published.

### Subagents: context hygiene

`claude-library/agents/security-reviewer.md` runs a scoped security review and returns evidence-backed findings without editing code; it preloads the `security-scan` skill, so copy both.
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
- **Skill or subagent**: create `claude-library/skills/<name>/SKILL.md` or `claude-library/agents/<name>.md`. Nothing to restow: it is used by copying it into a repo.
- **Anything stowed** (a new file directly under `claude/.claude/`): `stow --dir="$HOME/Desktop/dotfiles" --target="$HOME" --restow claude` (a bare `stow --restow claude` targets the parent of the repo, `~/Desktop`, not `~`).
- **Plugin**: `claude plugin install <plugin>@<marketplace>` (or `/plugin`); it is written to `settings.json`, so the next `bootstrap.sh` installs it.
- **MCP server**: see `README-mcp.md`.

## Walkthrough cheatsheet

| Question | Show |
| --- | --- |
| "What hooks do you use?" | `cat ~/.claude/settings.json`, then `hooks/` |
| "How do you stop the agent from breaking things?" | The demo command above: exit 2 and the message |
| "Workflows you've codified?" | `cat claude-library/skills/pr-description/SKILL.md`, or a repo's `.claude/skills/` |
| "External systems?" | `README-mcp.md` |
| "When does the agent fail?" | Hallucination: the compiler catches it. Confidently wrong: demand `file:line` evidence. Scope creep: the plan is approved before any code, and the agent stays inside it. Destructive: the hook blocks it. |

## Limits

- Nothing here runs unless I start Claude Code; there is no auto-deploy.
- Hooks stop obvious foot-guns; a person still reviews every diff.
- Hook events, skill layout and MCP config change as Claude Code evolves; check the official docs before quoting this.

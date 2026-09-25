#!/usr/bin/env bash
# PreToolUse hook (Bash): refuse destructive git operations.
# Reads the tool call JSON on stdin; exit 2 aborts the call and shows stderr to Claude.
set -euo pipefail

cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

block() {
  echo "Blocked: destructive git operation detected ($1). Ask the user to run it manually." >&2
  exit 2
}

case "$cmd" in
  *git*) ;;
  *) exit 0 ;;
esac

grep -Eq 'push[^|;&]*(--force|--force-with-lease|[[:space:]]-f([[:space:]]|$))' <<<"$cmd" && block "force push"
grep -Eq 'reset[^|;&]*--hard' <<<"$cmd" && block "reset --hard"
grep -Eq 'branch[^|;&]*[[:space:]]-D([[:space:]]|$)' <<<"$cmd" && block "branch -D"
grep -Eq 'clean[^|;&]*[[:space:]]-[a-zA-Z]*f' <<<"$cmd" && block "clean -f"
grep -Eq 'checkout[^|;&]*[[:space:]]--[[:space:]]+\.' <<<"$cmd" && block "checkout -- ."
grep -Eq 'restore[^|;&]*[[:space:]]\.([[:space:]]|$)' <<<"$cmd" && block "restore ."
grep -Eq 'commit[^|;&]*--amend' <<<"$cmd" && block "commit --amend"
grep -Eq -- '--no-verify' <<<"$cmd" && block "--no-verify"
grep -Eq -- '--no-gpg-sign' <<<"$cmd" && block "--no-gpg-sign"
grep -Eq 'reflog[^|;&]*expire' <<<"$cmd" && block "reflog expire"

exit 0

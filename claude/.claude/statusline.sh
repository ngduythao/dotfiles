#!/bin/sh
# Claude Code status line: model · effort · context · 5h and 7d limits · folder.
# Claude Code pipes the session JSON on stdin (fields documented at https://code.claude.com/docs/en/statusline). 
# All formatting happens in one jq call: macOS ships bash 3.2, and this runs on every update.
# Session cost is left out on purpose: it is a list-price estimate, not what a Pro/Max subscription is charged.

command -v jq >/dev/null 2>&1 || { printf 'claude'; exit 0; }

jq -rj '
  def paint(p): if p >= 80 then "\u001b[31m" elif p >= 50 then "\u001b[33m" else "\u001b[32m" end;
  def reset_in(t):
    ((t // 0) - now | floor) as $s
    | if $s <= 0 then ""
      elif $s >= 86400 then " \($s / 86400 | floor)d\($s % 86400 / 3600 | floor)h"
      elif $s >= 3600 then " \($s / 3600 | floor)h\($s % 3600 / 60 | floor)m"
      else " \($s / 60 | ceil)m" end;
  # Rate limits exist only for Pro/Max plans and only after the first API
  # response, so a missing window is skipped rather than shown as 0%.
  def window(name; w):
    if (w.used_percentage // null) == null then empty
    else "\(paint(w.used_percentage))\(name) \(w.used_percentage | round)%\(reset_in(w.resets_at))\u001b[0m" end;

  [ (.model.display_name // "?"),
    (.effort.level // empty),
    ((.context_window.used_percentage // null) as $c
      | if $c == null then empty else "\(paint($c))ctx \($c | round)%\u001b[0m" end),
    window("5h"; .rate_limits.five_hour),
    window("7d"; .rate_limits.seven_day),
    ((.workspace.current_dir // .cwd // "") | split("/") | map(select(. != "")) | .[-2:] | join("/") | select(. != ""))
  ] | join("\u001b[2m · \u001b[0m")
' 2>/dev/null || printf 'claude'

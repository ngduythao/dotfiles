# RTK

A Claude Code hook rewrites shell commands through `rtk` (for example `git status`
becomes `rtk git status`) to shorten their output. It is transparent; there is
nothing to call.

When the filtered output hides something you need, run the command unfiltered with
`rtk proxy <cmd>`, or read the full log whose path rtk prints after a truncated
result.

Never judge a check by rtk's summary line. Filtered linter output can read
"No issues found" or "Checked N files" while the command failed. For lint,
format, typecheck, test and build commands (biome, eslint, tsc, vitest, forge,
slither, go vet, …), run them with `rtk proxy` and decide pass or fail from the
exit code, for example `rtk proxy pnpm lint; echo "exit=$?"`.

Read `$?` right after the command, before anything else runs. In
`echo "$(basename "$PWD") exit=$?"` the command substitution runs first and
resets `$?` to 0, so a failed check reports success. Save it first:
`rtk proxy pnpm verify > log 2>&1; code=$?; echo "exit=$code"`.

# RTK

A Claude Code hook rewrites shell commands through `rtk` (for example `git status`
becomes `rtk git status`) to shorten their output. It is transparent; there is
nothing to call.

When the filtered output hides something you need, run the command unfiltered with
`rtk proxy <cmd>`, or read the full log whose path rtk prints after a truncated
result.

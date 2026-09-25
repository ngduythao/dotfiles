---
name: pr-description
description: Write a structured PR description from the current branch diff against main. Use after committing your work and before opening the PR.
---

You are writing the PR description for the current branch. Goal: reviewer can decide whether to open the diff and which files to start with — without reading every line.

## Steps

1. Identify base branch. Try in order: `main`, `master`, `develop`. Stop at first that exists.
   ```bash
   git rev-parse --verify main 2>/dev/null \
     || git rev-parse --verify master 2>/dev/null \
     || git rev-parse --verify develop
   ```

2. Inspect the diff:
   ```bash
   git log --oneline <base>..HEAD
   git diff <base>...HEAD --stat
   ```

3. Read the changed files where the commits and stat don't make the intent clear.

4. If `$ARGUMENTS` is set, treat it as the user's intent hint and weight it in the summary.

## Output format

Output the PR description as a fenced code block (so it's easy to copy). Use this template:

```
## Summary

- <bullet 1: what changed, focused on intent — "added X to solve Y" not "modified file Z">
- <bullet 2>
- <bullet 3>

## Why

<1-3 sentences on the underlying problem or goal. If a ticket/issue is referenced
in commits, link it. Skip this section if it duplicates Summary.>

## Notes for reviewer

<Things the reviewer should look at specifically: subtle invariants, migration
risk, breaking changes, files that look big but are mechanical. Skip if nothing
non-obvious.>

## Test plan

- [ ] <Concrete thing to verify, e.g. "POST /orders returns 422 when amount is 0">
- [ ] <Migration runs cleanly on a copy of prod>
- [ ] <Existing test suite passes>
```

## Constraints

- Title separately (under 70 chars, imperative mood): `<type>: <short summary>` where type ∈ feat/fix/refactor/chore/docs/test.
- Don't list every file changed — that's the diff's job.
- Don't write "improved code quality" or "various improvements" — concrete only.
- If the branch contains unrelated commits, surface that as a reviewer note rather than hiding it.
- If you can't determine intent from commits + diff, ask the user instead of guessing.

---
name: pr-description
description: Write a structured PR description from the current branch diff against the base branch (main, master or develop). Use after committing your work and before opening the PR.
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

- <one bullet per logical change, focused on intent — "added X to solve Y" not "modified file Z">

## Why

<The underlying problem or goal, as much as a reviewer needs to judge the change.
If a ticket/issue is referenced in commits, link it. Skip this section if it duplicates Summary.>

## Notes for reviewer

<Things the reviewer should look at specifically: subtle invariants, files that
look big but are mechanical. Skip if nothing non-obvious.>

## Risk

**Reversible:** <"yes, revert the commit", or "no" plus what cannot be undone: a migration
already applied, data rewritten, an event already published, a contract deployed>
**Blast radius:** <what breaks if this is wrong: one endpoint, every payment, another
service that consumes the event>

<Rollback steps, when reverting the commit is not enough.>

## Evidence

<Before and after for a behaviour change: the failing then passing test, or the old and
new output. Only what was really run; leave the section out rather than describe a run
that did not happen.>

## Test plan

- [ ] <A check this change needs, one per line, e.g. "POST /orders returns 422 when amount is 0".
      Add a migration or full-suite check only when the change calls for it.>
```

## Constraints

- Title separately (under 70 chars, imperative mood): `<type>: <short summary>` where type ∈ feat/fix/refactor/chore/docs/test.
- Don't list every file changed — that's the diff's job.
- Name every change concretely: what changed and what it is for.
- If the branch contains unrelated commits, surface that as a reviewer note rather than hiding it.
- Always fill in Risk. A schema migration, a changed event or API contract, a backfill, or anything deployed outside the repo makes the change not reversible by a plain revert: say so.
- Evidence comes from CI output or commands run in this conversation; a commit message that says tests pass is not evidence. Mask secrets in any output you quote.
- If you can't determine intent from commits + diff, ask the user instead of guessing.

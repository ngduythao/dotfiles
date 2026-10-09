---
name: diagnose
description: "Find the cause of a bug before fixing it: get a command that fails on this bug, shrink it, test ranked hypotheses, then fix with a regression test. Use when the cause is still unknown after a first look, the failure is intermittent, or a fix has already failed. Not for a bug whose cause is already evident."
argument-hint: "<the symptom, as the user sees it>"
---

# Diagnose

Symptom: $ARGUMENTS

If no symptom is given above, it is the failure described in the conversation.

No fix until the cause has been shown. Each step has a gate; do not start the next step
before the gate is met. The project's CLAUDE.md wins over this skill wherever they differ.
Mask secrets in every command and output you show.

## 1. A command that fails on this bug

Before forming any theory, get one command that fails because of this bug and will pass
once it is fixed. In order of preference: a test at the level that reaches the bug, a
request against the running app, a replay of a captured payload or log, a comparison of
the old and new version on the same input, a loop that repeats the trigger.

- It must check the symptom the user reported, not just "no error".
- Intermittent failure: repeat, parallelise or add load until most runs fail, and state
  the rate.
- Make it quick (seconds) and the same on every run: pin the time, the random seed and
  the data.

**Gate:** you have run the command and shown it failing. If you cannot build one, stop:
say what you tried and ask for access to an environment that reproduces it, a captured
log or payload, or permission to add temporary logging. Do not go on by guessing.

## 2. Shrink it

Remove inputs, steps, config and data one at a time, running the command after each
removal. Keep only what the failure needs.

**Gate:** removing any remaining piece makes the command pass, and the failure is still
the one the user reported, not a neighbouring one.

## 3. Hypotheses

Write 3–5 candidate causes, ranked, each with the result it predicts: "if X is the cause,
changing Y makes the failure go away". Drop any candidate you cannot write a prediction
for. Show the list to the user, then continue with your ranking unless they reorder it.

## 4. Test one at a time

One change per run, each tied to a prediction from step 3. Prefer a debugger, or a log
line at the point that separates two hypotheses. Start every temporary log line with one
unique tag (for example `DBG-7f3a`) so a single search finds them all later.

For slowness, measure before changing anything (timing, profile, query plan), then narrow
down by halving.

**Gate:** one hypothesis predicted every result you saw, and the others did not.

## 5. Fix

Turn the shrunk reproduction into a regression test at a level where the real failure
path runs. Show it failing, apply the fix, show it passing, then run the step 1 command
on the original, unshrunk scenario.

If no test level reaches the real path, say so instead of adding a test that could not
have caught the bug.

After three fixes that did not hold, stop and talk the design through with the user.

## 6. Clean up, report, then STOP

- the step 1 command passes, and the regression test passes (or why there is none);
- the project's verify command (lint, typecheck, test, build) passes, judged by exit code;
- tagged log lines and throwaway scripts are gone: show the search for the tag returning
  nothing;
- the cause in one sentence, and which hypothesis it was;
- what was not verified.

**Never commit or push.** The user reviews the diff and commits.

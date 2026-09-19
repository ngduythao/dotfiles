---
name: systematic-debugging
description: "Work through bugs, failing tests, surprising behavior, and incidents by proving the root cause with evidence before changing any code."
---

# Systematic Debugging

Find evidence of the real cause before suggesting a fix, working in four
stages. Size each stage to the problem: a failure that reproduces every time on
your machine can move through the stages in one short pass, while a wide
incident needs a written trail of evidence.

## The One Rule

```
UNDERSTAND THE ROOT CAUSE BEFORE CHANGING ANYTHING
```

Finish stage 1 before proposing any fix.

## The Four Stages

Go as deep in each stage as the risk and the uncertainty require.

### Stage 1: Find the Cause

**Before trying any fix:**

1. **Read the errors properly.** Go through every error and warning, and read the
   whole stack trace.
2. **Make it happen on demand.** Write down the exact steps and check whether it
   fails every time. If you can't reproduce it, collect more evidence first.
3. **Look at what changed.** Check the diff, recent commits, dependency upgrades,
   and config changes.
4. **Collect evidence across components.**
   - At every boundary between components, record the data going in and coming
     out, and confirm that environment settings reach where they should.
   - Run the failing flow once to see where it breaks.
   - Let that evidence tell you which component is at fault.
5. **Follow the bad data back.** Walk the wrong value back through the calls to
   where it came from (see `references/root-cause-tracing.md`).

### Stage 2: Compare With What Works

**Understand how this is supposed to work before fixing it:**

1. **Find a working example.** Look for similar code in the same codebase that
   behaves correctly.
2. **Check the reference.** Read enough of the docs or reference code to
   understand the contract and pattern before using it.
3. **List the differences.** Look into every difference that could explain the
   symptom; widen the search only if the evidence points that way.
4. **Know what it depends on.** Identify the components, settings, config, and
   environment the code needs.

### Stage 3: Test One Idea at a Time

**Work like an experiment:**

1. **Pick one hypothesis.** Make it specific: "X causes this, because Y."
2. **Test it with the smallest change.** Change one thing at a time, just enough
   to confirm or reject the idea.
3. **Confirm before moving on.** If the idea holds, go to stage 4. If not, form a
   new hypothesis; don't pile one fix on top of another.
4. **Be honest about what you don't know.** Say what is still unclear and ask for
   help instead of pretending to understand.

### Stage 4: Fix It

**Fix the cause, not the symptom:**

1. **Keep a reproduction.** Save the simplest runnable way to trigger the bug; if
   there is a suitable test setup and the test is worth keeping, add a test that
   fails before the fix.
2. **Make one fix.** Change only what addresses the root cause, with no unrelated
   improvements mixed in.
3. **Check the fix.** The original reproduction and the affected tests must pass,
   and the problem must actually be gone.
4. **If the fix doesn't work,** count the attempts so far.
   - Fewer than three: go back to stage 1 with the new evidence.
   - **Three or more: stop and question the design.** If every fix uncovers
     another shared-state or coupling problem, the design itself may be wrong.
     Talk it through with the user before trying anything else.

## Warning Signs: Stop and Go Back

If you notice yourself thinking any of these:
- "Patch it now, figure it out later"
- "Let me just change X and see"
- "Make several changes, then run the tests"
- "No need to run it, I can tell"
- "It's probably X, I'll fix that"
- "I don't really get it, but this might work"
- "Just one more try" (after two or more already)

**Every one of them means:** stop and return to stage 1.

## When the User Signals You're Off Track

- "Isn't that happening?": you assumed without checking
- "Will that show us...?": you should have gathered evidence
- "Stop guessing": you are proposing fixes without understanding
- "Go back to basics": revisit the diagnosis or the design, not just the symptom
- "Are we stuck?" (said with frustration): the current approach isn't working

**When you hear this:** stop and return to stage 1.

## Tempting Excuses

| Excuse | Why it's wrong |
|--------|----------------|
| "It's simple, no process needed" | Simple bugs have root causes too |
| "It's urgent, there's no time" | Investigating properly is faster than guessing |
| "Let me try this first, then investigate" | The first fix sets the habit; investigate from the start |

## Done Means

A reproducible starting point, a root cause backed by evidence, a focused fix,
and fresh verification sized to the change. Hide secrets in any logs you share.

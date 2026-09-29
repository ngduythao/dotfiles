---
name: systematic-debugging
description: "Work through bugs, failing tests, surprising behavior, and incidents by proving the root cause with evidence before changing any code."
---

# Systematic Debugging

Find evidence of the real cause before suggesting a fix. Size the work to the
problem: a failure that reproduces every time on your machine can take one short
pass, while a wide incident needs a written trail of evidence.

## How to Work

Nothing changes in the code until evidence points at a cause. First make the
failure happen on demand and write down the exact steps; if it won't reproduce,
collect more evidence instead of guessing. When the fault could sit in more than
one component, record what crosses each boundary (including environment
settings) and let that show which component is at fault, then walk the bad
value back to where it started (see `references/root-cause-tracing.md`).

Test one specific hypothesis at a time ("X causes this, because Y") with the
smallest change that confirms or rejects it. If it is rejected, form a new one;
don't pile one fix on top of another. Say what is still unclear instead of
pretending to understand.

The fix changes only what addresses the root cause. Keep the simplest runnable
reproduction; if there is a suitable test setup and the test is worth keeping,
add a test that fails before the fix. The fix is done when the reproduction and
the affected tests pass and the problem is actually gone.

After three failed fixes, stop and talk the design through with the user before
trying anything else: when every fix uncovers another shared-state or coupling
problem, the design itself may be wrong. If the user questions the diagnosis,
go back to collecting evidence.

## Done Means

A reproducible starting point, a root cause backed by evidence, a focused fix,
and fresh verification sized to the change. Hide secrets in any logs you share.

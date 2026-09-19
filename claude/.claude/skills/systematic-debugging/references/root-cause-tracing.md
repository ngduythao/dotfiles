# Tracing a Bug Back to Its Source

Work backwards along the chain of calls until you reach whatever first set the
problem in motion.

## The Idea

**Walk the call chain back to the first trigger and fix the problem there.**

A bug often shows itself far down the call stack, a long way from where it
began. Patching only the spot where the error appears can leave the real cause in
place, ready to fail somewhere else.

## When It Helps

- The failure happens deep inside the run, not at the entry point.
- The stack trace is a long chain of calls.
- It is unclear where the bad data came from.
- You don't know which test or code path sets the problem off.

## Step by Step

The example: a nightly job deletes files from the wrong directory.

### 1. Look at the symptom
```
removed 214 files from /srv/app/uploads
```
The job was meant to clean `/srv/app/uploads/tmp`, not the whole uploads folder.

### 2. Find the line that does the damage
```go
os.RemoveAll(filepath.Join(root, subdir))
```

### 3. Ask who called it
```text
cleanup.Run(root, subdir)
  ← called by scheduler.nightly()
  ← called by main, with values from config
```

### 4. Check the values on the way up
- `subdir == ""`
- `filepath.Join(root, "")` is just `root`
- so the whole uploads folder was treated as the temp folder

### 5. Find where the bad value started
```go
cfg.TmpSubdir = os.Getenv("TMP_SUBDIR") // unset on the new server
```

## Adding a Stack Trace

If reading the code does not get you there, record the context at the point of
failure:

```go
func removeTree(dir string) error {
	log.Printf("DEBUG removeTree dir=%q cwd=%q\n%s", dir, mustGetwd(), debug.Stack())
	return os.RemoveAll(dir)
}
```

Write the diagnostic to stderr (or an unbuffered logger) so it still shows up
when the normal logger or the test runner hides output.

**Run it and collect the output:**
```bash
go test ./... 2>&1 | grep 'DEBUG removeTree'
```

**Read the traces for:**
- the test or entry point that shows up
- the line that made the call
- a pattern: always the same test, or the same argument?

## Finding the Test That Leaks State

If a test only fails alongside others, use the project's test runner to narrow
down which earlier test changes shared state: run subsets, halving the set each
time, in a throwaway workspace.

## Remember

**Don't stop where the error surfaced.** Keep going back to the first trigger.

Once you have the immediate cause:
- Can you go one level further up? Then trace back again.
- Is this where it started? Then fix it here.
- Afterwards, add validation at the trust boundaries where it would stop the same
  problem coming back.

## Worked Example

**Symptom:** the nightly cleanup emptied the whole uploads folder.

**Chain of causes:**
1. `os.RemoveAll` ran on `root`, because `subdir` was empty
2. `cleanup.Run` received an empty `subdir`
3. the scheduler passed `cfg.TmpSubdir` through unchanged
4. config read `TMP_SUBDIR` with no default
5. the new server never set that variable

**Root cause:** a required setting that silently defaulted to an empty string.

**Fix:** config fails at startup when `TMP_SUBDIR` is missing.

**Extra layers of defense:**
- Layer 1: `cleanup.Run` refuses an empty `subdir`
- Layer 2: the target must lie strictly inside `root`, never equal it
- Layer 3: a dry-run mode lists what would be removed
- Layer 4: log the resolved path before anything is deleted

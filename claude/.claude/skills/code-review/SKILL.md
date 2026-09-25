---
name: code-review
description: Run a financial-grade code review checklist (money, transactions, idempotency, concurrency, audit, security, observability, smart contracts and on-chain integration). Defaults to current branch diff; pass a path as $ARGUMENTS to scope review.
---

You are doing a **financial-services-grade** code review. Be specific and skeptical. Banking, securities, payment companies all care about the same fundamentals — money handling, transaction boundaries, idempotency, audit trail, concurrency safety. Use this checklist.

## Scope

- If `$ARGUMENTS` is empty: review the diff between current branch and `main` (or `master`, whichever exists).
- If `$ARGUMENTS` is a path: review files under that path.
- If `$ARGUMENTS` looks like a PR URL: fetch the diff via `gh pr diff`.

## Checklist

### Money handling
- Amounts stored as `BigDecimal` or `long` minor units — **never** `double` or `float`.
- Currency stored alongside amount (paired in same value object or column).
- Rounding mode explicit at every major↔minor conversion. `HALF_EVEN` for accounting unless there's a domain reason.
- Money equality respects both amount AND currency (`100 USD != 100 VND`).
- Arithmetic between different currencies rejected, not silently coerced.

### Transaction management (Spring/Hibernate)
- `@Transactional` on **public** methods only — Spring AOP proxy won't intercept private.
- No self-invocation (`this.method()` from another method in same class bypasses the proxy → annotation silently no-ops).
- `rollbackFor` explicit for checked exceptions in money path; default rollback is unchecked-only.
- `readOnly = true` on GET service methods.
- `spring.jpa.open-in-view: false` — surfaces N+1 in service layer, not HTTP rendering.

### Idempotency
- POST endpoints that mutate state accept an `Idempotency-Key` header.
- Webhooks deduplicate by `(provider, provider_ref)` with a DB-level unique constraint.
- Outbox pattern: DB mutation + event record in the same transaction.
- Idempotency check at **DB constraint** level — not just `if (exists)` in app code (race).

### Concurrency
- "Check state then update" uses `SELECT ... FOR UPDATE` or `@Version` optimistic lock.
- Pessimistic lock spans the full check-then-act, not just the check.
- Atomic SQL UPDATE (`WHERE status = 'PENDING'`) for state machine transitions instead of read-modify-write.
- No `synchronized` block holding a DB connection (deadlock risk).

### Audit & compliance
- Immutable audit log for every state transition on a regulated aggregate (order, payment, refund, position).
- Tamper-evident: hash chain (HMAC of `prev_hash || row`) or DB-level append-only constraint (trigger rejecting UPDATE/DELETE).
- `created_by`, `updated_by`, `actor_kind` recorded on mutations.
- PII (email, phone, name, card) masked in logs and exception traces.

### Security
- Webhook signature verified BEFORE acquiring DB locks (don't burn CPU on spam).
- Constant-time comparison for HMAC / token comparison (`MessageDigest.isEqual`, not `equals`).
- JWT secret validated for entropy at boot, not just non-blank.
- Refresh tokens hashed before storage; rotation invalidates the entire token family on reuse.
- Password hashing: Argon2id or bcrypt (cost ≥ 10), never SHA-256 alone.

### Observability
- Request ID / correlation ID in MDC, propagated to outbound calls.
- Structured logging (JSON), not string concat.
- Metrics for: request latency, payment counter by status, webhook receive/reject.
- `/livez` and `/readyz` separate endpoints, readiness checks dependencies.

### Smart contracts (Solidity)
- **Pull, not push**, for fees and payouts: no transfer to an arbitrary recipient inside a hot
  path (swap, payment). A recipient that reverts (contract without `receive`) must not block
  everyone else — with push it can turn a pool into a honeypot.
- Checks-effects-interactions: state and events written before external calls; reentrancy guard
  where untrusted contracts are called.
- Access control: who can call each setter, `initialize`, upgrade; one-shot setters stay one-shot;
  zero-address checks where zero would lock funds or setup forever.
- Signatures: EIP-712 domain binds `chainId` and `verifyingContract`; ids/nonces cannot replay;
  the signing key holds only its role, not admin; a front-runnable `permit` is wrapped in
  `try/catch` so the allowance path still works.
- **Never `tx.origin` for identity** — it is the bundler under ERC-4337 and the relayer for
  meta-transactions.
- Upgradeable code: `_disableInitializers()` in the implementation constructor, storage gaps or
  namespaced storage, who holds the upgrade role. An upgradeable contract called on every
  transaction is a trust and liveness dependency.
- Rounding direction explicit; a split sums exactly to the total (remainder to one named party);
  a fuzz/invariant test proves "held == owed".
- Non-standard ERC-20s (no return value, fee-on-transfer, rebasing): `SafeERC20` and a token
  allowlist, or an explicit statement that they are unsupported.
- Uniswap v4 hooks: permissions match the address bits; callbacks `onlyPoolManager`;
  `beforeInitialize` limits which pools may use the hook; per-pool state keyed by `PoolId`;
  `sender` is the router, not the user; `take` on the input side before settlement needs the
  PoolManager to already hold that currency — prefer ERC-6909 `mint`; sign of the returned delta.
- Events carry what an indexer needs (indexed where filtered), so nobody has to index a
  singleton's events for the whole chain.
- Slither has been run; every finding is fixed or silenced inline with the reason.

### On-chain integration (backend / frontend)
- Paid/credited state comes from chain events after finality (N confirmations or the `finalized`
  tag), never from a client-reported tx hash.
- Log processing is idempotent on `(chainId, txHash, logIndex)`; a cursor plus a rescan window;
  block hash re-checked before confirming (reorg); an RPC error is not treated as a reorg.
- Token amounts are bigint / decimal strings end to end, never a JS `number`.
- Frontend: simulate before write; exact approvals, not unlimited; `amountOutMin` from the quote;
  the form is locked while a transaction is pending; "confirming" until the backend or indexer
  says otherwise.
- Addresses and ABIs have one source (deployment manifest + build artifacts), and the manifest is
  not written unless the broadcast succeeded.

### Testing
- Unit tests for state machine transitions including invalid cases.
- Integration tests with real DB (Testcontainers), not in-memory swap.
- Constant-time comparison test (statistical timing assertion).
- Idempotency tested: same request twice → one effect.

## Output format

Per finding:

```
**[SEVERITY]** <Short title>
  file:line — <Evidence>
  Why: <What can go wrong in production>
  Fix: <Concrete change>
```

Severity:
- **HIGH** — can lose or duplicate money, corrupt state, or break the audit trail in production.
- **MEDIUM** — a real weakness under load, failure, or abuse, with limited impact.
- **LOW** — nice-to-have, doesn't block.

End with:

- **Strong points** — what's done well.
- **Overall grade** (A/B/C/D).
- **Quick wins** — the highest-impact, lowest-effort fixes.

## Anti-patterns to call out

- A bare "Looks good" — if you find nothing, say so and name what you checked.
- Generic comments like "consider adding tests" — say which scenario is untested and why it matters.
- Restating the diff — focus on what's wrong or risky, not what's there.

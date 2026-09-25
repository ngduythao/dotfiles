---
name: security-scan
description: "Examine a chosen part of the code for reachable security risks: authentication, authorization, injection, exposed secrets, vulnerable dependencies, and similar."
---

# Security Audit

By default this is an audit only; make fixes only if asked. Tie every finding to
an attack that can actually be carried out, and keep confirmed defects separate
from places where evidence is missing. Mask credentials everywhere in the output.
If a check could not be run, say so instead of implying it passed.

## Method

### 1. Settle the Scope
Turn the given glob, or the word `full`, into a list of files. Examine that scope
and the trust boundaries around it, and say which parts were not reviewed.

### 2. Threats by Type (STRIDE)
Go through each category in turn:
- **S**poofing: weaknesses in identity and authentication
- **T**ampering: input validation and integrity protection
- **R**epudiation: missing audit logs
- **I**nformation disclosure: leaking data or secrets
- **D**enial of service: rate limits and exhausting resources
- **E**levation of privilege: broken access control and gaps in role checks

### 3. OWASP Top 10
The checklist follows the 2025 edition of the OWASP Top 10 (A01 to A10); name the
edition when you report. Per-category checks are in
`references/stride-owasp-checklist.md`.

### 4. Dependencies
Run the stack's own vulnerability scanner (`govulncheck` for Go, `npm audit`
for Node.js, `pip-audit` for Python; more in the checklist) and keep only the
issues the code can actually reach.

### 5. Secrets
Search for API keys, passwords, tokens, and private keys written into the code,
using the regular expressions under "Secret Patterns" in
`references/stride-owasp-checklist.md`.

### 6. Grade the Findings
Give every supported finding a severity from the table below.

---

## Severity Levels

| Severity | Meaning | When to fix |
|----------|---------|-------------|
| Critical | Can be exploited now; risk of a data breach or remote code execution | Right away; stop the release |
| High | Can be exploited with moderate effort, with serious impact | In the current sprint |
| Medium | Hard to exploit, or the impact is limited | In the next sprint |
| Low | A theoretical risk or an extra layer of defense | Backlog |
| Info | A good-practice suggestion with no direct risk | Optional |

---

## Report

For every supported finding give the severity, file and line, how an attacker
could reach it, the impact, the evidence, and a practical fix. Finish with what
was in scope and what could not be verified. Don't present the audit as a
compliance certification.

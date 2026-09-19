# Security Checklist: STRIDE and OWASP

Only use the checks that fit the system and its threat model; the examples here
are not requirements for every project.

This supports `security-scan`, mainly during step 2 (STRIDE) and step 3 (OWASP
Top 10).

---

## STRIDE

### Spoofing (authentication)
- [ ] Every endpoint requires authentication, unless it is deliberately public
- [ ] Passwords are hashed with bcrypt or Argon2, never MD5 or SHA-1
- [ ] JWTs carry an expiry (`exp`) and are verified on the server
- [ ] Session cookies set `Secure`, `HttpOnly`, and `SameSite`
- [ ] Sensitive actions can require a second factor
- [ ] OAuth and OIDC flows send a `state` value to stop CSRF
- [ ] No service or dependency still uses default credentials

### Tampering (integrity)
- [ ] All user input is checked for type, length, and format
- [ ] SQL and NoSQL queries bind parameters instead of joining strings
- [ ] Every form that changes state carries a CSRF token
- [ ] Calls between services are authenticated and integrity-protected in a way
      that fits the trust model, such as HMAC or mTLS
- [ ] Uploaded files are checked for real type (magic bytes), size, and content
- [ ] Untrusted data is not deserialised, or only inside a sandbox
- [ ] Each endpoint accepts only the right HTTP methods; GET never changes data

### Repudiation (logging)
- [ ] Logins, logouts, and failed logins are logged
- [ ] Authorization failures are logged with the user and resource involved
- [ ] Changes to data are logged with who made them and when
- [ ] Logs hold no passwords, tokens, or personal data
- [ ] Logs cannot be altered: append-only storage or a central collector
- [ ] Logs are kept as long as the project and any regulations require

### Information disclosure
- [ ] Production error messages show no stack traces
- [ ] API responses leave out internal details consumers are not meant to see
- [ ] Sensitive data is encrypted at rest (AES-256 or similar)
- [ ] All traffic uses TLS 1.2 or later; sensitive endpoints never use plain HTTP
- [ ] No secrets are written into the source (see Secret Patterns below)
- [ ] `.env` and credential files are in `.gitignore`
- [ ] Responses return only the fields that are needed

### Denial of service
- [ ] Login and other sensitive endpoints are rate limited
- [ ] The server or gateway limits request body size
- [ ] Every list endpoint is paginated; no query is unbounded
- [ ] Calls to external APIs and databases have timeouts
- [ ] Connection pools have a sensible size and are released properly
- [ ] Regular expressions are checked for catastrophic backtracking (ReDoS)
- [ ] Background jobs have concurrency limits and a dead-letter queue

### Elevation of privilege
- [ ] Role checks happen on the server, not in the client
- [ ] One user cannot reach another user's records by changing an ID (IDOR)
- [ ] Admin endpoints use their own, stricter authentication middleware
- [ ] Gaining higher privileges requires authenticating again
- [ ] Service accounts have only the permissions they need
- [ ] Third-party integrations are granted the smallest set of permissions

---

## OWASP Top 10 (2021) at a Glance

| # | Category | Look for |
|---|----------|----------|
| A01 | Broken Access Control | Missing authorization checks, IDOR, loose CORS, path traversal |
| A02 | Cryptographic Failures | MD5/SHA-1 hashing, data stored in plaintext, no TLS, weak ciphers |
| A03 | Injection | SQL, NoSQL, OS command, LDAP, or template injection from unchecked input |
| A04 | Insecure Design | No threat model, flaws in business logic, abuse cases never tested |
| A05 | Security Misconfiguration | Default credentials, detailed error pages, features or ports left on |
| A06 | Vulnerable Components | Old dependencies, known CVEs, libraries without patches |
| A07 | Authentication Failures | Brute force, credential stuffing, session fixation, weak tokens |
| A08 | Data Integrity Failures | Unsigned updates, unchecked deserialisation, a compromised CI/CD pipeline |
| A09 | Logging Failures | Security events not logged, no alerts, too little monitoring |
| A10 | SSRF | URLs from users fetched without checks, reaching internal services |

---

## Secret Patterns

Search source files with these expressions. A match is only a candidate: confirm
that it is a real credential, and how exposed and powerful it is, before giving
it a severity. Never print the value itself.

| Kind of secret | Pattern |
|---|---|
| Private key in PEM form | `-----BEGIN (RSA \|EC \|DSA \|OPENSSH )?PRIVATE KEY-----` |
| AWS key ID | `AKIA[0-9A-Z]{16}` |
| AWS secret key assigned in code | `(?i)aws[_-]?secret[_-]?access[_-]?key\s*[:=]\s*['"][A-Za-z0-9/+]{40}['"]` |
| GitHub personal token | `ghp_[A-Za-z0-9]{36}` |
| Stripe live or test secret | `sk_(live\|test)_[A-Za-z0-9]{24,}` |
| JWT | `eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+` |
| Bearer token written out | `(?i)bearer\s+[A-Za-z0-9\-._~+/]{20,}` |
| API key assigned in code | `(?i)(api[_-]?key\|apikey)\s*[:=]\s*['"][A-Za-z0-9\-_]{20,}['"]` |
| Password assigned in code | `(?i)(password\|passwd\|pwd)\s*[:=]\s*['"][^'"]{8,}['"]` |

In the table, `\|` is an escaped pipe; use a plain `|` when running the pattern.

> To cut false positives, ignore matches in `*.test.*`, `*.spec.*`, `*.example`,
> and `*.md` files when the value is obviously a placeholder, such as
> `YOUR_KEY_HERE` or `<your-token>`.

---

## Scanning Dependencies

Use the scanner that matches the stack, ask for machine-readable output where it
exists, and attach the result to the report:

- Go: `govulncheck ./...`
- Node.js: `npm audit --json`
- Python: `pip-audit --format json`
- Rust: `cargo audit`
- Java with Maven: `mvn dependency-check:check`

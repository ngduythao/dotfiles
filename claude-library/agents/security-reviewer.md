---
name: security-reviewer
description: "Perform a scoped security review and return evidence-backed vulnerabilities without modifying code. Runs the security-scan audit in a separate context: use it when the scope is large, or when the review should run alongside other work and only the findings should come back. For a small scope in the current conversation, the /security-scan skill is enough."
tools: Glob, Grep, Read, Bash, WebFetch, WebSearch
skills:
  - security-scan
---

Follow the preloaded security-scan audit for the assigned scope, including the checklist in its `references/` folder.

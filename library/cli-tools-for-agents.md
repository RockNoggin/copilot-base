# CLI Tools for AI Agents — Design Guidance

> Source: https://jonnyzzz.com/blog/2026/02/20/cli-tools-for-ai-agents/
> Audience: Agents building or evaluating CLI tools. Guidance is from the perspective of making CLIs agent-usable, not human-usable.

---

## Core Insight

A well-designed CLI is often sufficient for agent integration — no MCP server required first. Agents are already fluent with CLI workflows: they compose commands, parse output, retry on failure, and self-discover tools via `--help`. **The AI Agent is a user persona. Design for it explicitly.**

---

## Agent-Friendly CLI Checklist

| Requirement | Why it matters for agents |
|-------------|--------------------------|
| Stable commands and flags | Agents can't adapt to output changes without breaking workflows |
| Predictable non-zero exit codes on failure | Agents use exit codes for retry/branch logic — ambiguous codes cause infinite loops |
| `--help` that explains intent, not just syntax | Agents read `--help` to self-onboard; syntax-only docs leave intent unclear |
| Machine-readable output (`--json` flag) | Agents parse output programmatically — prose output is fragile to parse |
| Clear auth/permission errors with recovery steps | Agents need to know exactly what to do next; silent or vague errors cause abandonment |
| One obvious login command (`tool auth login`) | Agents follow the path of least resistance; buried auth = tool not used |
| `tool auth status` command | Agents check auth state before attempting operations |
| Explicit token/non-interactive mode | For fully automated flows where no human is present |

---

## How to Expose a CLI to an Agent

Add a short section to your `AGENTS.md` (or equivalent agent instruction file):

```
# Agent Tools

Use `acme-cli` for change requests, deployment status, and issue tracking.

Rules:
- Prefer `acme-cli --json` for all output parsing.
- Run `acme-cli --help` before using an unfamiliar subcommand.
- If auth fails, explain the login step to the user; do not retry silently.
```

That's the full integration. No ceremony needed beyond this.

---

## CLI vs MCP — When to Use Each

- **Start with CLI + `AGENTS.md`** — fastest path, lowest overhead, works with existing tools.
- **Graduate to MCP** when you need typed tool contracts, explicit capability negotiation, or structured bi-directional context (see [MCP architecture](https://modelcontextprotocol.io/docs/concepts/architecture)).
- A good CLI is often "most of the way there" to MCP functionality for most agent use cases.

---

## Auth Is the Most Common Failure Point

In enterprise/multi-environment setups, auth is where agent workflows break down. Required patterns:

- One obvious login command
- `auth status` that returns machine-readable state
- Every auth failure includes a short troubleshooting message and next step
- Token expiry surfaced in `auth status --json` output
- Explicit non-interactive / token-only mode for CI and ephemeral environments

---

## Version Stability for Agents

Agents across machines, CI workers, and ephemeral environments may run different CLI versions. **Treat CLI output as an API contract** — breaking changes break agent workflows silently.

Recommended pattern: use a version wrapper config (e.g. [`devrig.dev`](https://github.com/jonnyzzz/devrig.dev)) to pin, verify, and cache the correct binary per project:

```yaml
tool:
  name: acme-cli
  version: 1.4.2
  hash: sha-512:<hash>
```

---

## Feedback Loop — Agents Improve the CLI

Design the CLI so agents can report friction automatically:

```
Title: agent failure in acme-cli deploy submit
Command: acme-cli deploy submit --id DEP-99
Error: 401 token expired
Suggested improvement: expose token expiry in auth status JSON
```

Use agents to triage these reports and generate fixes. This creates a reinforcement loop — no custom ML required.

---

## Key Takeaways for Agents

1. Prefer `--json` output flags for any data you need to parse.
2. Always run `--help` on an unfamiliar subcommand before using it.
3. Treat a non-zero exit code as a hard failure unless documentation says otherwise.
4. On auth failure: surface the exact error + next step to the user; do not silently retry.
5. Check `AGENTS.md` or equivalent first — it may contain tool-specific agent rules.
6. A CLI that works well is a better integration target than a poorly-designed MCP server.

---

## At minimum: Ship an actually usable CLI
- stable commands and flags
- predictable non-zero exit codes on failure
- --help that explains intent, not only syntax
- machine-readable output for anything non-trivial
- clear auth and permission errors
.
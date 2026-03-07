# Copilot Instructions

## About This Repository

This is a personal GitHub Copilot configuration template (`copilot-base`). It provides a starting point for consistent Copilot behavior across new projects. The three main artifacts are:

| Path | Purpose |
|------|---------|
`library/` holds reference material (not auto-loaded). `tools.md` tracks useful CLI/MCP tools.

## General Behavior

- Be concise and direct. Prefer short, clear responses over lengthy explanations.
- Minimize the number of files changed to accomplish a task — surgical, precise edits.
- Never delete working code unless explicitly asked.
- Comment only when the code genuinely needs clarification; avoid obvious comments.

## Code Style

- Follow the conventions already present in the file being edited.
- Use consistent naming: prefer descriptive names over abbreviations.
- Prefer explicit over implicit — make intent clear from the code itself.
- Comments should explain *why* something is done, not *what* the code does.

## Git

- Commit messages should be short and imperative (e.g. "Add user auth", "Fix null check").
- Keep commits focused on a single concern.

## When Unsure

- Ask a clarifying question rather than guessing at intent.
- Prefer the simplest solution that satisfies the requirement.

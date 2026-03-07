# Tools — CLI & MCP

Tools I like but don't load by default. Add here for reference when setting up a new project or environment.

---

## MCP Tools

### mcptools
> A CLI for interacting with MCP (Model Context Protocol) servers via stdio and HTTP transport.

- **Repo:** https://github.com/f/mcptools
- **Language:** Go | **License:** MIT
- **Install:** `go install github.com/f/mcptools/cmd/mcp@latest`
- **Why useful:** Lets you call, list, and test MCP server tools directly from the terminal — great for debugging MCP integrations without needing a full editor setup.

---

## CLI Tools

### Microsoft Work IQ (`workiq`)
> CLI + MCP server that connects AI assistants to Microsoft 365 Copilot data (emails, meetings, documents, Teams messages, people).

- **Docs:** https://learn.microsoft.com/en-us/microsoft-365-copilot/extensibility/workiq-overview
- **Repo:** https://github.com/microsoft/work-iq-mcp
- **Install:** `npm install -g @microsoft/workiq`
- **Requires:** Microsoft 365 subscription with Copilot license + admin consent in Entra tenant
- **Key commands:**
  - `workiq accept-eula` — accept EULA (required on first use)
  - `workiq ask -q "<question>"` — query M365 data from terminal
  - `workiq mcp` — start as MCP server for VS Code / Copilot CLI
- **Why useful:** Lets agents query workplace context (meetings, emails, docs) directly — no browser needed.

---

## Notes

- Tools listed here are **not** auto-loaded — load them manually when needed.
- When adding a tool, include: repo link, install command, and a one-liner on why it's useful.

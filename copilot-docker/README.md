# copilot-docker

Run GitHub Copilot CLI in **YOLO mode** (`--yolo`) inside a Docker container, controlled from a PowerShell client on Windows.

> **Why?** YOLO mode disables all permission prompts — dangerous on a host machine, but safe inside a disposable container where the blast radius is limited to your mounted project directory.

## Quick Start

```powershell
# 1. Set your GitHub token (if not already in your environment)
$env:GH_TOKEN = "ghp_your_token_here"

# 2. Build the Docker image
cd copilot-docker
docker build -t copilot-yolo ./docker

# 3. Import the PowerShell module
Import-Module ./client/copilot.psm1

# 4. Start a container for your project
Start-CopilotContainer -Workspace "D:\MyProject" -Build

# 5. Run a batch prompt
Invoke-CopilotBatch -Workspace "D:\MyProject" -Prompt "add error handling to auth.js"

# 6. Or open an interactive session
Enter-CopilotSession -Workspace "D:\MyProject"
```

## Architecture

### Option A — Thin Shell Client (Implemented)

No custom server. The container is a pre-configured environment; the PowerShell client wraps `docker run` / `docker exec` directly.

```
┌───────────────────────────────────────────────┐
│  Windows Host                                 │
│                                               │
│  copilot.psm1                                 │
│   Invoke-CopilotBatch  ──► docker exec <name> │
│   Enter-CopilotSession ──► docker exec -it    │
│   Start-CopilotContainer ► docker run -d      │
│                                   │           │
│                                   ▼           │
│                     ┌──────────────────────┐  │
│                     │  Docker Container    │  │
│                     │  copilot (pre-auth)  │  │
│                     │  /workspace mounted  │  │
│                     └──────────────────────┘  │
└───────────────────────────────────────────────┘
```

### Option B — HTTP API + SSE (Future)

A Node.js server inside the container exposes `POST /run` (SSE streaming) and `WS /session` (interactive PTY relay). Enables programmatic access from any language.

### Option C — Docker Sandbox (Recommended for Security)

Use Docker Desktop 4.58+'s built-in Sandbox feature for microVM isolation, credential proxying, and network policies:

```bash
docker sandbox create copilot ./your-project -- --yolo
docker sandbox run copilot-your-project
```

## PowerShell Functions

| Function | Description |
|---|---|
| `Start-CopilotContainer` | Start a persistent container for a workspace |
| `Invoke-CopilotBatch` | Send a batch prompt (streams output live) |
| `Enter-CopilotSession` | Open interactive YOLO session |
| `Stop-CopilotContainer` | Stop and remove a container |
| `Get-CopilotContainers` | List running Copilot containers |

## Docker Compose

Alternative to the PowerShell module for simple setups:

```powershell
$env:WORKSPACE_PATH = "D:\MyProject"
$env:GH_TOKEN = "ghp_..."
docker compose up -d
docker exec -it copilot-workspace copilot --yolo
```

## Security Notes

- **Always commit/stash before YOLO sessions** — Copilot can delete files in the mounted workspace
- **Never hardcode tokens** — use host environment variables only
- **Review `.git/hooks/`** after sessions — Copilot could inject hooks
- **Consider `--network=none`** for air-gapped runs (standard Docker shares host network)
- **Use Docker Sandbox** (Option C) when maximum isolation is needed

## File Structure

```
copilot-docker/
  docker/
    Dockerfile          # Node.js 20 + Copilot CLI + gh CLI
    entrypoint.sh       # Container startup & config
    .env.example        # Environment variable template
  client/
    copilot.psm1        # PowerShell client module
  api/                  # (Phase 2 — HTTP API server)
  docker-compose.yml    # Compose file for simple usage
```

## Related

- [Research: Running Copilot CLI Safely in YOLO Mode](https://docs.docker.com/ai/sandboxes/agents/copilot/)
- [Docker Sandbox Network Policies](https://docs.docker.com/ai/sandboxes/network-policies/)
- [copilot_here — Community Docker Wrapper](https://github.com/GordonBeeming/copilot_here)

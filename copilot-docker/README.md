# copilot-docker

Run GitHub Copilot CLI in **YOLO mode** (`--yolo`) inside a Docker container, controlled from a PowerShell client on Windows.

> **Why?** YOLO mode disables all permission prompts — dangerous on a host machine, but safe inside a disposable container where the blast radius is limited to your mounted project directory.

## Prerequisites

- **Docker Desktop** running on Windows
- **GitHub CLI (`gh`)** authenticated (`gh auth login`) with a Copilot-enabled account
- **PowerShell 7+** (or 5.1+ with Windows PowerShell)

## Setup (One-Time)

```powershell
# 1. Build the Docker image
cd D:\GIT\copilot-base\copilot-docker
docker build -t copilot-yolo ./docker

# 2. Add to your PowerShell profile (auto-loads module + token on every shell)
Add-Content $PROFILE @'

# GitHub Copilot Docker - YOLO mode module
Import-Module D:\GIT\copilot-base\copilot-docker\client\copilot.psm1
if (-not $env:GH_TOKEN) {
    try {
        $token = gh auth token 2>&1
        if ($LASTEXITCODE -eq 0 -and $token) { $env:GH_TOKEN = $token }
        else { Write-Warning "gh CLI not authenticated. Run 'gh auth login'." }
    } catch { Write-Warning "gh CLI not found." }
}
'@
```

Restart your terminal, and all `*-Copilot*` functions are available with authentication handled automatically.

## Usage

### Start a container for your project

Each workspace gets its own persistent container. The container stays alive between prompts so there's no cold start.

```powershell
Start-CopilotContainer -Workspace "D:\MyProject"
```

The container is named automatically based on the folder (e.g., `copilot-myproject`). Override with `-Name`:

```powershell
Start-CopilotContainer -Workspace "D:\MyProject" -Name "copilot-frontend"
```

If the image hasn't been built yet, add `-Build`:

```powershell
Start-CopilotContainer -Workspace "D:\MyProject" -Build
```

### Run a batch prompt (fire-and-forget)

Send a task and stream the output live. Copilot runs autonomously with `--autopilot --yolo`.

```powershell
Invoke-CopilotBatch -Workspace "D:\MyProject" -Prompt "add error handling to auth.js"
```

Control how many autonomous steps Copilot can take (default: 10):

```powershell
Invoke-CopilotBatch -Workspace "D:\MyProject" -Prompt "refactor the API layer" -MaxContinues 20
```

### Open an interactive session

Full interactive terminal — you chat with Copilot in YOLO mode inside the container:

```powershell
Enter-CopilotSession -Workspace "D:\MyProject"
```

Exit the session with `Ctrl+C` or `/exit`. The container stays running for future use.

### List running containers

```powershell
Get-CopilotContainers
```

### Stop and clean up

```powershell
# Stop one container
Stop-CopilotContainer -Workspace "D:\MyProject"

# Or by name
Stop-CopilotContainer -Name "copilot-frontend"
```

### Using Docker Compose (alternative)

For simpler setups without the PowerShell module:

```powershell
$env:WORKSPACE_PATH = "D:\MyProject"
$env:GH_TOKEN = "ghp_..."
docker compose up -d

# Interactive session
docker exec -it copilot-workspace copilot --yolo

# Batch prompt
docker exec -t copilot-workspace copilot --autopilot --yolo -p "your prompt here"
```

## Typical Workflow

```powershell
# 1. Commit your work first (safety net)
cd D:\MyProject
git add -A && git commit -m "checkpoint before YOLO session"

# 2. Start the container
Start-CopilotContainer -Workspace "D:\MyProject"

# 3. Run your task
Invoke-CopilotBatch -Workspace "D:\MyProject" -Prompt "add unit tests for the auth module"

# 4. Review what changed
git diff

# 5. Keep or discard
git add -A && git commit -m "YOLO: added auth tests"
# or: git checkout .
```

## Security Checklist

| Practice | Priority |
|---|---|
| **Commit/stash before every YOLO session** | 🔴 Critical |
| **Never hardcode tokens** — use `$env:GH_TOKEN` only | 🔴 Critical |
| **Review `.git/hooks/`** after sessions (Copilot could inject hooks) | 🟡 High |
| **Set `--max-autopilot-continues`** to cap runaway loops | 🟡 High |
| **Use `--network=none`** for air-gapped runs when possible | 🟡 High |
| **Review all file changes** before committing | 🟡 High |

## PowerShell Function Reference

| Function | Parameters | Description |
|---|---|---|
| `Start-CopilotContainer` | `-Workspace` (req), `-Name`, `-Image`, `-Build` | Start a persistent container for a workspace |
| `Invoke-CopilotBatch` | `-Prompt` (req), `-Workspace`/`-Name`, `-MaxContinues` | Send a batch prompt, streams output live |
| `Enter-CopilotSession` | `-Workspace`/`-Name` | Open full interactive YOLO session |
| `Stop-CopilotContainer` | `-Workspace`/`-Name` | Stop and remove a container |
| `Get-CopilotContainers` | (none) | List all running Copilot containers |

All functions accept either `-Workspace` (auto-generates container name from folder) or `-Name` (explicit container name).

## Architecture

The PowerShell client wraps `docker run` / `docker exec` — no custom server required.

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

### Docker Sandbox Alternative (Recommended for Maximum Security)

Docker Desktop 4.58+ offers built-in Sandbox with microVM isolation, credential proxying, and network policies:

```bash
docker sandbox create copilot ./your-project -- --yolo
docker sandbox run copilot-your-project
```

See the [Docker Sandbox documentation](https://docs.docker.com/ai/sandboxes/agents/copilot/) for details on Sandbox vs standard Docker tradeoffs.

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

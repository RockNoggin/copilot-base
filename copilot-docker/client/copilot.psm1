<#
.SYNOPSIS
    PowerShell client for managing Copilot CLI inside Docker containers.

.DESCRIPTION
    Provides functions to start/stop Docker containers running Copilot CLI in
    YOLO mode, execute batch prompts, and enter interactive sessions.

.NOTES
    Requires Docker Desktop to be running.
#>

$script:DefaultImage = "copilot-yolo"

function Test-DockerAvailable {
    try {
        $null = docker version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Docker daemon is not running. Start Docker Desktop and try again."
        }
    } catch [System.Management.Automation.CommandNotFoundException] {
        throw "Docker is not installed or not in PATH. Install Docker Desktop from https://docker.com/products/docker-desktop/"
    }
}

function Get-SanitizedName {
    param([string]$Path)
    $name = (Split-Path -Leaf $Path) -replace '[^a-zA-Z0-9_-]', '-'
    return "copilot-$($name.ToLower())"
}

function Start-CopilotContainer {
    <#
    .SYNOPSIS
        Starts a persistent Copilot CLI container for the given workspace.
    .PARAMETER Workspace
        Host path to mount as /workspace in the container.
    .PARAMETER Name
        Override the auto-generated container name.
    .PARAMETER Image
        Docker image to use (default: copilot-yolo).
    .PARAMETER Build
        Build the image from copilot-docker/docker/ before starting.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Workspace,

        [string]$Name,

        [string]$Image = $script:DefaultImage,

        [switch]$Build
    )

    Test-DockerAvailable

    if (-not (Test-Path $Workspace)) {
        throw "Workspace path does not exist: $Workspace"
    }
    $Workspace = (Resolve-Path $Workspace).Path

    if (-not $Name) {
        $Name = Get-SanitizedName $Workspace
    }

    # Check if container already exists
    $existing = docker ps -aq --filter "name=^${Name}$" 2>$null
    if ($existing) {
        $running = docker ps -q --filter "name=^${Name}$" 2>$null
        if ($running) {
            Write-Host "Container '$Name' is already running." -ForegroundColor Yellow
            return
        }
        Write-Host "Starting existing container '$Name'..." -ForegroundColor Cyan
        docker start $Name
        return
    }

    if ($Build) {
        $dockerDir = Join-Path $PSScriptRoot "..\docker"
        Write-Host "Building image '$Image'..." -ForegroundColor Cyan
        docker build -t $Image $dockerDir
        if ($LASTEXITCODE -ne 0) { throw "Docker build failed." }
    }

    Write-Host "Starting container '$Name' with workspace '$Workspace'..." -ForegroundColor Cyan

    $envArgs = @()
    if ($env:GH_TOKEN)     { $envArgs += @("-e", "GH_TOKEN=$($env:GH_TOKEN)") }
    if ($env:GITHUB_TOKEN) { $envArgs += @("-e", "GITHUB_TOKEN=$($env:GITHUB_TOKEN)") }

    docker run -d `
        --name $Name `
        -v "${Workspace}:/workspace" `
        -t `
        @envArgs `
        $Image

    if ($LASTEXITCODE -ne 0) { throw "Failed to start container." }
    Write-Host "Container '$Name' is ready." -ForegroundColor Green
}

function Invoke-CopilotBatch {
    <#
    .SYNOPSIS
        Sends a batch prompt to Copilot CLI inside the container.
    .PARAMETER Prompt
        The prompt to send to Copilot.
    .PARAMETER Workspace
        Host workspace path (used to resolve container name).
    .PARAMETER Name
        Container name override.
    .PARAMETER MaxContinues
        Maximum autopilot continuation steps (default: 10).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [string]$Workspace,
        [string]$Name,
        [int]$MaxContinues = 10
    )

    if (-not $Name) {
        if (-not $Workspace) { throw "Specify -Workspace or -Name." }
        $Name = Get-SanitizedName $Workspace
    }

    Test-DockerAvailable

    $running = docker ps -q --filter "name=^${Name}$" 2>$null
    if (-not $running) { throw "Container '$Name' is not running. Use Start-CopilotContainer first." }

    Write-Host "Running batch prompt on '$Name'..." -ForegroundColor Cyan

    docker exec -t $Name `
        copilot --autopilot --yolo `
        --max-autopilot-continues $MaxContinues `
        -p "$Prompt"
}

function Enter-CopilotSession {
    <#
    .SYNOPSIS
        Opens an interactive Copilot CLI session inside the container.
    .PARAMETER Workspace
        Host workspace path (used to resolve container name).
    .PARAMETER Name
        Container name override.
    #>
    [CmdletBinding()]
    param(
        [string]$Workspace,
        [string]$Name
    )

    if (-not $Name) {
        if (-not $Workspace) { throw "Specify -Workspace or -Name." }
        $Name = Get-SanitizedName $Workspace
    }

    Test-DockerAvailable

    $running = docker ps -q --filter "name=^${Name}$" 2>$null
    if (-not $running) { throw "Container '$Name' is not running. Use Start-CopilotContainer first." }

    Write-Host "Entering interactive session on '$Name'..." -ForegroundColor Cyan
    docker exec -it $Name copilot --yolo
}

function Stop-CopilotContainer {
    <#
    .SYNOPSIS
        Stops and removes a Copilot CLI container.
    .PARAMETER Workspace
        Host workspace path (used to resolve container name).
    .PARAMETER Name
        Container name override.
    #>
    [CmdletBinding()]
    param(
        [string]$Workspace,
        [string]$Name
    )

    if (-not $Name) {
        if (-not $Workspace) { throw "Specify -Workspace or -Name." }
        $Name = Get-SanitizedName $Workspace
    }

    Test-DockerAvailable

    Write-Host "Stopping container '$Name'..." -ForegroundColor Cyan
    $null = docker stop $Name 2>&1
    if ($LASTEXITCODE -eq 0) {
        docker rm $Name 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Container '$Name' removed." -ForegroundColor Green
        } else {
            Write-Warning "Container '$Name' stopped but could not be removed. Run 'docker rm $Name' manually."
        }
    } else {
        Write-Warning "Container '$Name' was not running or does not exist."
    }
}

function Get-CopilotContainers {
    <#
    .SYNOPSIS
        Lists all running Copilot CLI containers.
    #>
    [CmdletBinding()]
    param()

    Test-DockerAvailable

    docker ps --filter "name=copilot-" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}"
}

# Export module functions
Export-ModuleMember -Function @(
    'Start-CopilotContainer'
    'Invoke-CopilotBatch'
    'Enter-CopilotSession'
    'Stop-CopilotContainer'
    'Get-CopilotContainers'
)

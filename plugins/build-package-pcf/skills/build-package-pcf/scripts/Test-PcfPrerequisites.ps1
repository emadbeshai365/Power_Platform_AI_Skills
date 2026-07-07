[CmdletBinding()]
param(
    [switch]$RequirePac,
    [switch]$RequireBuildTool
)

$ErrorActionPreference = 'Stop'
$missing = [System.Collections.Generic.List[string]]::new()

function Get-ToolInfo {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [string[]]$VersionArguments,
        [switch]$Required
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $command) {
        if ($Required) { $script:missing.Add($Name) }
        return [pscustomobject]@{ Tool = $Name; Status = 'Missing'; Version = ''; Path = '' }
    }

    $version = ''
    try {
        $version = (& $command.Source @VersionArguments 2>&1 | Select-Object -First 1).ToString().Trim()
    }
    catch {
        $version = "Detected; version check failed: $($_.Exception.Message)"
    }

    [pscustomobject]@{
        Tool = $Name
        Status = 'Found'
        Version = $version
        Path = $command.Source
    }
}

$results = @(
    Get-ToolInfo -Name 'node' -VersionArguments @('--version') -Required
    Get-ToolInfo -Name 'npm' -VersionArguments @('--version') -Required
    Get-ToolInfo -Name 'pac' -VersionArguments @('--version') -Required:$RequirePac
)

$dotnet = Get-ToolInfo -Name 'dotnet' -VersionArguments @('--version')
$msbuild = Get-ToolInfo -Name 'msbuild' -VersionArguments @('-version')
$results += $dotnet
$results += $msbuild

if ($RequireBuildTool -and $dotnet.Status -eq 'Missing' -and $msbuild.Status -eq 'Missing') {
    $missing.Add('dotnet-or-msbuild')
}

$results | Format-Table -AutoSize

if ($missing.Count -gt 0) {
    Write-Error ("Missing required PCF tools: {0}. See https://learn.microsoft.com/en-us/power-apps/developer/component-framework/create-custom-controls-using-pcf" -f ($missing -join ', '))
    exit 1
}

Write-Host 'PCF prerequisite check passed.'


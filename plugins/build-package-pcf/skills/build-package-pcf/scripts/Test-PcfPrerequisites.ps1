[CmdletBinding()]
param(
    [switch]$RequirePac,
    [switch]$RequireBuildTool,
    [int]$MinimumNodeMajor = 18,
    [version]$MinimumPacVersion = '1.37.0'
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

$nodeResult = $results | Where-Object Tool -eq 'node' | Select-Object -First 1
if ($nodeResult.Status -eq 'Found' -and $nodeResult.Version -match 'v?(\d+)\.') {
    if ([int]$Matches[1] -lt $MinimumNodeMajor) {
        $missing.Add("node>=$MinimumNodeMajor")
        $nodeResult.Status = 'Unsupported'
    }
}

$pacResult = $results | Where-Object Tool -eq 'pac' | Select-Object -First 1
if ($RequirePac -and $pacResult.Status -eq 'Found' -and $pacResult.Version -match '(\d+\.\d+\.\d+)') {
    if ([version]$Matches[1] -lt $MinimumPacVersion) {
        $missing.Add("pac>=$MinimumPacVersion")
        $pacResult.Status = 'Unsupported'
    }
}

$dotnet = Get-ToolInfo -Name 'dotnet' -VersionArguments @('--version')
$msbuild = Get-ToolInfo -Name 'msbuild' -VersionArguments @('-version')
$results += $dotnet
$results += $msbuild

if ($RequireBuildTool -and $dotnet.Status -eq 'Missing' -and $msbuild.Status -eq 'Missing') {
    $missing.Add('dotnet-or-msbuild')
}

$results | Format-Table -AutoSize

if ($missing.Count -gt 0) {
    Write-Error ("Missing or unsupported PCF tools: {0}. See https://learn.microsoft.com/en-us/power-apps/developer/component-framework/create-custom-controls-using-pcf" -f ($missing -join ', '))
    exit 1
}

Write-Host 'PCF prerequisite check passed.'

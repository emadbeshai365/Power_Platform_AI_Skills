[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ComponentPath,
    [Parameter(Mandatory)] [string]$SolutionPath,
    [ValidateSet('Release', 'Debug')] [string]$Configuration = 'Release',
    [switch]$SkipInstall,
    [switch]$SkipLint,
    [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Resolve-SingleFile {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Filter,
        [Parameter(Mandatory)] [string]$Label
    )

    $resolved = Resolve-Path -LiteralPath $Path
    $item = Get-Item -LiteralPath $resolved.Path
    if (-not $item.PSIsContainer) {
        if ($item.Name -notlike $Filter) { throw "$Label must match ${Filter}: $($item.FullName)" }
        return $item
    }

    $matches = @(Get-ChildItem -LiteralPath $item.FullName -Filter $Filter -File)
    if ($matches.Count -ne 1) {
        throw "Expected exactly one ${Filter} in $($item.FullName); found $($matches.Count). Pass the exact file path."
    }
    return $matches[0]
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory)] [string]$Executable,
        [Parameter(Mandatory)] [string[]]$Arguments,
        [Parameter(Mandatory)] [string]$Description
    )

    Write-Host "==> $Description"
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Description failed with exit code $LASTEXITCODE." }
}

$pcfProject = Resolve-SingleFile -Path $ComponentPath -Filter '*.pcfproj' -Label 'Component project'
$componentDirectory = $pcfProject.Directory.FullName
$packageJsonPath = Join-Path $componentDirectory 'package.json'
if (-not (Test-Path -LiteralPath $packageJsonPath)) { throw "package.json was not found in $componentDirectory." }

$solutionProject = Resolve-SingleFile -Path $SolutionPath -Filter '*.cdsproj' -Label 'Solution project'
$solutionDirectory = $solutionProject.Directory.FullName
$npm = Get-Command 'npm.cmd','npm' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $npm) { throw 'npm is required but was not found on PATH.' }

$packageJson = Get-Content -LiteralPath $packageJsonPath -Raw | ConvertFrom-Json
Push-Location $componentDirectory
try {
    if (-not $SkipInstall -and -not (Test-Path -LiteralPath (Join-Path $componentDirectory 'node_modules'))) {
        if (Test-Path -LiteralPath (Join-Path $componentDirectory 'package-lock.json')) {
            Invoke-Checked -Executable $npm.Source -Arguments @('ci') -Description 'Restore locked npm dependencies'
        }
        else {
            Invoke-Checked -Executable $npm.Source -Arguments @('install') -Description 'Install npm dependencies'
        }
    }

    if (-not $SkipLint -and $packageJson.scripts -and $packageJson.scripts.PSObject.Properties.Name -contains 'lint') {
        Invoke-Checked -Executable $npm.Source -Arguments @('run', 'lint') -Description 'Run lint checks'
    }
    if (-not $SkipTests -and $packageJson.scripts -and $packageJson.scripts.PSObject.Properties.Name -contains 'test') {
        Invoke-Checked -Executable $npm.Source -Arguments @('run', 'test') -Description 'Run component tests'
    }

    if ($Configuration -eq 'Release') {
        Invoke-Checked -Executable $npm.Source -Arguments @('run', 'build', '--', '--buildMode', 'production') -Description 'Build production PCF bundle'
    }
    else {
        Invoke-Checked -Executable $npm.Source -Arguments @('run', 'build') -Description 'Build development PCF bundle'
    }
}
finally {
    Pop-Location
}

$dotnet = Get-Command 'dotnet' -ErrorAction SilentlyContinue | Select-Object -First 1
$msbuild = Get-Command 'msbuild' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($dotnet) {
    Invoke-Checked -Executable $dotnet.Source -Arguments @('build', $solutionProject.FullName, '--configuration', $Configuration) -Description 'Build Dataverse solution project'
}
elseif ($msbuild) {
    Invoke-Checked -Executable $msbuild.Source -Arguments @($solutionProject.FullName, '/restore', "/p:Configuration=$Configuration") -Description 'Build Dataverse solution project'
}
else {
    throw 'Neither dotnet nor msbuild was found on PATH.'
}

$outputDirectory = Join-Path $solutionDirectory ("bin/{0}" -f $Configuration)
$packages = @()
if (Test-Path -LiteralPath $outputDirectory) {
    $packages = @(Get-ChildItem -LiteralPath $outputDirectory -Filter '*.zip' -File -Recurse | Sort-Object LastWriteTime -Descending)
}

if ($packages.Count -eq 0) {
    throw "The solution build succeeded, but no ZIP package was found under $outputDirectory. Inspect the .cdsproj output settings."
}

Write-Host 'Generated solution package(s):'
$packages | Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize
$packages.FullName

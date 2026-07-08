[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ComponentPath,
    [Parameter(Mandatory)] [string]$SolutionPath,
    [ValidateSet('Release', 'Debug')] [string]$Configuration = 'Release',
    [ValidateSet('Managed', 'Unmanaged', 'Both')] [string]$ExpectedPackageType,
    [switch]$SkipInstall,
    [switch]$AllowUnlockedInstall,
    [switch]$SkipLint,
    [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$buildStartedUtc = [DateTime]::UtcNow
Add-Type -AssemblyName System.IO.Compression.FileSystem

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

$auditScript = Join-Path $PSScriptRoot 'Inspect-PcfProject.ps1'
if (Test-Path -LiteralPath $auditScript) {
    Write-Host '==> Audit PCF project'
    & $auditScript -ProjectPath $pcfProject.FullName
    if (-not $?) { throw 'PCF project audit failed.' }
}

$solutionProject = Resolve-SingleFile -Path $SolutionPath -Filter '*.cdsproj' -Label 'Solution project'
$solutionDirectory = $solutionProject.Directory.FullName
$solutionXml = [xml](Get-Content -LiteralPath $solutionProject.FullName -Raw)
$packageTypeNodes = @($solutionXml.SelectNodes("//*[local-name()='SolutionPackageType']"))
$packageType = if ($packageTypeNodes.Count -gt 0) { [string]$packageTypeNodes[-1].InnerText } else { 'NotExplicitlySet' }
$projectReferences = @($solutionXml.SelectNodes("//*[local-name()='ProjectReference']") | ForEach-Object { [string]$_.Include })
if ($projectReferences.Count -eq 0) {
    throw "The solution project contains no ProjectReference. Add the PCF project with pac solution add-reference."
}
$resolvedReferences = @($projectReferences | ForEach-Object {
    [System.IO.Path]::GetFullPath((Join-Path $solutionDirectory $_))
})
if ($resolvedReferences -notcontains $pcfProject.FullName) {
    throw "The solution does not reference the exact component project: $($pcfProject.FullName)"
}
if ($ExpectedPackageType -and $packageType -ne $ExpectedPackageType) {
    throw "Expected SolutionPackageType '$ExpectedPackageType' but the .cdsproj declares '$packageType'."
}
if ($packageType -eq 'NotExplicitlySet') {
    Write-Warning 'SolutionPackageType is not explicitly set. Do not infer managed/unmanaged intent from Release configuration.'
}
else {
    Write-Host "SolutionPackageType: $packageType"
}
$npm = Get-Command 'npm.cmd','npm' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $npm) { throw 'npm is required but was not found on PATH.' }

$packageJson = Get-Content -LiteralPath $packageJsonPath -Raw | ConvertFrom-Json
$scriptsObject = if ($packageJson.PSObject.Properties.Name -contains 'scripts') { $packageJson.scripts } else { $null }
Push-Location $componentDirectory
try {
    if (-not $SkipInstall -and -not (Test-Path -LiteralPath (Join-Path $componentDirectory 'node_modules'))) {
        if (Test-Path -LiteralPath (Join-Path $componentDirectory 'package-lock.json')) {
            Invoke-Checked -Executable $npm.Source -Arguments @('ci') -Description 'Restore locked npm dependencies'
        }
        elseif (-not $AllowUnlockedInstall) {
            throw 'package-lock.json is missing. Commit a lockfile or explicitly pass -AllowUnlockedInstall for non-release experimentation.'
        }
        else {
            Invoke-Checked -Executable $npm.Source -Arguments @('install') -Description 'Install npm dependencies'
        }
    }

    if (-not $SkipLint -and $scriptsObject -and $scriptsObject.PSObject.Properties.Name -contains 'lint') {
        Invoke-Checked -Executable $npm.Source -Arguments @('run', 'lint') -Description 'Run lint checks'
    }
    if (-not $SkipTests -and $scriptsObject -and $scriptsObject.PSObject.Properties.Name -contains 'test') {
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
    $packages = @(Get-ChildItem -LiteralPath $outputDirectory -Filter '*.zip' -File -Recurse |
        Where-Object { $_.LastWriteTimeUtc -ge $buildStartedUtc.AddSeconds(-2) } |
        Sort-Object LastWriteTime -Descending)
}

if ($packages.Count -eq 0) {
    throw "The solution build succeeded, but no ZIP package created by this run was found under $outputDirectory. Inspect the .cdsproj output settings."
}

Write-Host 'Generated solution package(s):'
$artifactFacts = $packages | ForEach-Object {
    $archive = [System.IO.Compression.ZipFile]::OpenRead($_.FullName)
    try {
        $solutionEntry = $archive.Entries | Where-Object { $_.FullName -ieq 'solution.xml' } | Select-Object -First 1
        if (-not $solutionEntry) { throw "Package does not contain solution.xml: $($_.FullName)" }
        $reader = [System.IO.StreamReader]::new($solutionEntry.Open())
        try { [xml]$packageSolution = $reader.ReadToEnd() } finally { $reader.Dispose() }
        $managedNode = $packageSolution.SelectSingleNode("//*[local-name()='Managed']")
        $artifactType = if ($managedNode -and [string]$managedNode.InnerText -eq '1') { 'Managed' } else { 'Unmanaged' }
    }
    finally {
        $archive.Dispose()
    }
    if ($ExpectedPackageType -and $ExpectedPackageType -ne 'Both' -and $artifactType -ne $ExpectedPackageType) {
        throw "Artifact $($_.Name) is '$artifactType', expected '$ExpectedPackageType'."
    }
    [pscustomobject]@{
        Type = $artifactType
        FullName = $_.FullName
        Length = $_.Length
        LastWriteTime = $_.LastWriteTime
        Sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    }
}
$artifactFacts | Format-Table -AutoSize
$packages.FullName

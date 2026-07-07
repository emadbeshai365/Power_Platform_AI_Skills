[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ProjectPath,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$facts = [ordered]@{}

function Resolve-SingleProjectFile {
    param([string]$Path)

    $resolved = Resolve-Path -LiteralPath $Path
    $item = Get-Item -LiteralPath $resolved.Path
    if (-not $item.PSIsContainer) {
        if ($item.Extension -ne '.pcfproj') {
            throw "ProjectPath must be a .pcfproj or a directory containing one: $($item.FullName)"
        }
        return $item
    }

    $matches = @(Get-ChildItem -LiteralPath $item.FullName -Filter '*.pcfproj' -File)
    if ($matches.Count -ne 1) {
        throw "Expected exactly one .pcfproj in $($item.FullName); found $($matches.Count). Pass the exact .pcfproj path."
    }
    return $matches[0]
}

function Add-ErrorMessage {
    param([string]$Message)
    $script:errors.Add($Message)
}

function Add-WarningMessage {
    param([string]$Message)
    $script:warnings.Add($Message)
}

$project = Resolve-SingleProjectFile -Path $ProjectPath
$projectDirectory = $project.Directory.FullName
$facts.Project = $project.FullName
$facts.ProjectDirectory = $projectDirectory

$packageJsonPath = Join-Path $projectDirectory 'package.json'
if (-not (Test-Path -LiteralPath $packageJsonPath)) {
    Add-ErrorMessage "package.json is missing beside the .pcfproj: $packageJsonPath"
}
else {
    try {
        $package = Get-Content -LiteralPath $packageJsonPath -Raw | ConvertFrom-Json
        $facts.PackageName = if ($package.PSObject.Properties.Name -contains 'name') { $package.name } else { '(missing)' }
        $scriptsObject = if ($package.PSObject.Properties.Name -contains 'scripts') { $package.scripts } else { $null }
        $scriptNames = if ($scriptsObject) { @($scriptsObject.PSObject.Properties.Name) } else { @() }
        $facts.PackageScripts = $scriptNames
        if ($scriptNames -notcontains 'build') { Add-ErrorMessage 'package.json does not define a build script.' }
        if ($scriptNames -notcontains 'start') { Add-WarningMessage 'package.json does not define a start script for the local harness.' }
        if ($scriptNames -notcontains 'lint') { Add-WarningMessage 'package.json does not define a lint script.' }
        if ($scriptNames -notcontains 'test') { Add-WarningMessage 'package.json does not define a test script.' }
        if (-not (Test-Path -LiteralPath (Join-Path $projectDirectory 'package-lock.json'))) {
            Add-WarningMessage 'No package-lock.json was found; reproducible npm ci restores are unavailable.'
        }
    }
    catch {
        Add-ErrorMessage "package.json could not be parsed: $($_.Exception.Message)"
    }
}

$excludedSegments = @('node_modules', 'out', 'obj', 'bin')
$manifestCandidates = @(Get-ChildItem -LiteralPath $projectDirectory -Filter 'ControlManifest.Input.xml' -File -Recurse | Where-Object {
    $relative = $_.FullName.Substring($projectDirectory.Length).TrimStart('\')
    -not ($excludedSegments | Where-Object { $relative -match "(^|\\)$([regex]::Escape($_))(\\|$)" })
})

if ($manifestCandidates.Count -ne 1) {
    Add-ErrorMessage "Expected exactly one source ControlManifest.Input.xml; found $($manifestCandidates.Count)."
}
else {
    $manifest = $manifestCandidates[0]
    $facts.Manifest = $manifest.FullName
    $controlDirectory = $manifest.Directory.FullName

    try {
        [xml]$xml = Get-Content -LiteralPath $manifest.FullName -Raw
        $control = $xml.manifest.control
        if ($null -eq $control) { throw 'The manifest does not contain a control element.' }

        $namespace = [string]$control.namespace
        $constructor = [string]$control.constructor
        $version = [string]$control.version
        $controlType = [string]$control.'control-type'
        if ([string]::IsNullOrWhiteSpace($controlType)) { $controlType = 'standard' }

        $facts.Namespace = $namespace
        $facts.Constructor = $constructor
        $facts.Version = $version
        $facts.ControlType = $controlType
        $facts.ComponentId = "$namespace.$constructor"

        if ([string]::IsNullOrWhiteSpace($namespace)) { Add-ErrorMessage 'Manifest namespace is missing.' }
        if ([string]::IsNullOrWhiteSpace($constructor)) { Add-ErrorMessage 'Manifest constructor is missing.' }
        if ($version -notmatch '^\d+\.\d+\.\d+(\.\d+)?$') {
            Add-WarningMessage "Manifest version '$version' is not a conventional 3- or 4-part numeric version."
        }
        if ($controlType -notin @('standard', 'virtual')) {
            Add-ErrorMessage "Unsupported control-type '$controlType'."
        }

        $properties = @($control.SelectNodes('property'))
        $datasets = @($control.SelectNodes('data-set'))
        $facts.PropertyCount = $properties.Count
        $facts.DatasetCount = $datasets.Count
        $facts.Architecture = if ($facts.DatasetCount -gt 0) { "$controlType dataset" } else { "$controlType field" }

        $propertyNames = @($properties | ForEach-Object { [string]$_.name })
        $duplicateProperties = @($propertyNames | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
        if ($duplicateProperties.Count -gt 0) {
            Add-ErrorMessage "Duplicate manifest property names: $($duplicateProperties -join ', ')"
        }

        $resourcesNode = $control.SelectSingleNode('resources')
        $resourceNodes = if ($null -ne $resourcesNode) { @($resourcesNode.ChildNodes | Where-Object NodeType -eq 'Element') } else { @() }
        if ($null -eq $resourcesNode) { Add-ErrorMessage 'Manifest does not contain a resources element.' }
        $resourceFacts = @()
        foreach ($resource in $resourceNodes) {
            $pathAttribute = $resource.Attributes['path']
            if ($null -eq $pathAttribute) { continue }
            $relativePath = $pathAttribute.Value
            $absolutePath = Join-Path $controlDirectory $relativePath
            $exists = Test-Path -LiteralPath $absolutePath
            $resourceFacts += [pscustomobject]@{ Type = $resource.Name; Path = $relativePath; Exists = $exists }
            if (-not $exists) { Add-ErrorMessage "Manifest resource does not exist: $relativePath" }
        }
        $facts.Resources = $resourceFacts

        $platformLibraries = @($control.SelectNodes('resources/platform-library') | ForEach-Object { [string]$_.name })
        $facts.PlatformLibraries = $platformLibraries
        if ($controlType -eq 'virtual' -and $platformLibraries -notcontains 'React') {
            Add-ErrorMessage 'Virtual control does not declare the React platform library.'
        }
        if ($controlType -eq 'standard' -and $platformLibraries.Count -gt 0) {
            Add-WarningMessage 'Standard control declares platform-library resources; verify this matches a supported architecture.'
        }

        $codeResource = $resourceNodes | Where-Object Name -eq 'code' | Select-Object -First 1
        if ($null -eq $codeResource) {
            Add-ErrorMessage 'Manifest does not declare a code resource.'
        }
        else {
            $entryPath = Join-Path $controlDirectory $codeResource.path
            $facts.EntryPoint = $entryPath
            if (Test-Path -LiteralPath $entryPath) {
                $entrySource = Get-Content -LiteralPath $entryPath -Raw
                if ($controlType -eq 'virtual' -and $entrySource -notmatch 'ComponentFramework\.ReactControl') {
                    Add-WarningMessage 'Virtual manifest entry point does not visibly implement ComponentFramework.ReactControl.'
                }
                if ($controlType -eq 'standard' -and $entrySource -notmatch 'ComponentFramework\.StandardControl') {
                    Add-WarningMessage 'Standard manifest entry point does not visibly implement ComponentFramework.StandardControl.'
                }
                if ($controlType -eq 'virtual' -and $entrySource -match 'ReactDOM\.render') {
                    Add-WarningMessage 'Virtual control entry point calls ReactDOM.render; return a ReactElement from updateView instead.'
                }
            }
        }

        $features = @($control.SelectNodes('feature-usage/uses-feature') | ForEach-Object { [string]$_.name })
        $domains = @($control.SelectNodes('external-service-usage/domain') | ForEach-Object { [string]$_.InnerText })
        $facts.Features = $features
        $facts.ExternalDomains = $domains

        if (-not (Test-Path -LiteralPath (Join-Path $controlDirectory 'generated\ManifestTypes.d.ts'))) {
            Add-WarningMessage 'generated/ManifestTypes.d.ts is absent. This is normal before restore/build but should be generated during validation.'
        }
    }
    catch {
        Add-ErrorMessage "ControlManifest.Input.xml could not be parsed: $($_.Exception.Message)"
    }
}

try {
    [xml]$pcfXml = Get-Content -LiteralPath $project.FullName -Raw
    $buildModes = @($pcfXml.SelectNodes('//PcfBuildMode') | ForEach-Object { [string]$_.InnerText })
    $facts.PcfBuildMode = if ($buildModes.Count -gt 0) { $buildModes -join ',' } else { '(not set; command controls mode)' }
    if ($buildModes.Count -gt 0 -and $buildModes -notcontains 'production') {
        Add-WarningMessage "PcfBuildMode is '$($buildModes -join ',')'; do not use it for a production push."
    }
}
catch {
    Add-ErrorMessage ".pcfproj could not be parsed: $($_.Exception.Message)"
}

$result = [ordered]@{
    Valid = $errors.Count -eq 0
    Facts = $facts
    Errors = @($errors)
    Warnings = @($warnings)
}

if ($Json) {
    $result | ConvertTo-Json -Depth 8
}
else {
    Write-Host 'PCF project summary'
    [pscustomobject]$facts | Select-Object Project, ComponentId, Version, Architecture, PropertyCount, DatasetCount, PcfBuildMode | Format-List

    if ($errors.Count -gt 0) {
        Write-Host 'Errors:' -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    }
    if ($warnings.Count -gt 0) {
        Write-Host 'Warnings:' -ForegroundColor Yellow
        $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
    if ($errors.Count -eq 0) {
        Write-Host 'PCF project audit passed.' -ForegroundColor Green
    }
}

if ($errors.Count -gt 0) { exit 1 }

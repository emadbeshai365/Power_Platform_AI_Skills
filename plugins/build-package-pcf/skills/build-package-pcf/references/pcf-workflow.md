# PCF workflow and packaging reference

## Contents

- Project choices
- Prerequisites and initialization
- Development commands
- Solution packaging
- Deployment boundary
- Official sources

## Project choices

Choose the contract before implementation:

| Choice | Use |
| --- | --- |
| `field` | A component bound to one or more scalar properties/columns. |
| `dataset` | A component that presents a record set with paging, sorting, filtering, selection, or command behavior. |
| `--framework none` | Direct DOM rendering or a small control without React. |
| `--framework react` | React virtual controls and platform React/Fluent libraries. Prefer for substantial interactive UI. |

Confirm the intended hosts: model-driven apps, canvas apps, or Power Pages. APIs and manifest features are not identical across hosts.

## Prerequisites and initialization

Required tools:

- Node.js LTS and npm
- Microsoft Power Platform CLI (`pac`), preferably through Power Platform Tools for Visual Studio Code or the supported Windows installer
- .NET SDK 6 or newer, or Visual Studio MSBuild, for solution builds

Initialize from an empty component directory:

```powershell
pac pcf init --namespace Contoso.Controls --name StatusPicker --template field --framework react --run-npm-install
```

PAC constraints include:

- Component names contain only letters and digits and cannot start with a digit.
- Namespaces contain letters, digits, and periods; segment starts cannot be digits.
- Publisher prefixes are 2-8 alphanumeric characters, start with a letter, and cannot start with `mscrm`.

## Development commands

Run from the component directory containing `package.json`:

```powershell
npm install
npm run build
npm start watch
npm run build -- --buildMode production
```

Prefer `npm ci` when a committed `package-lock.json` exists and dependencies need restoration. Use existing lint/test scripts when defined. Do not deploy a development bundle to Dataverse.

The local harness is useful for inputs, outputs, sizing, and basic interaction. It does not reproduce all Web API, dataset, navigation, device, or host behavior.

## Solution packaging

Create the solution project in a sibling folder rather than inside the control source folder when possible:

```powershell
mkdir StatusPickerSolution
cd StatusPickerSolution
pac solution init --publisher-name Contoso --publisher-prefix cts
pac solution add-reference --path ../StatusPicker
```

Configure package output in the generated `.cdsproj`:

```xml
<PropertyGroup>
  <SolutionPackageType>Managed</SolutionPackageType>
</PropertyGroup>
```

Valid values are `Managed`, `Unmanaged`, and `Both`. This choice is independent from development/production bundle mode. Use Release configuration to embed a production PCF build:

```powershell
dotnet build ./StatusPickerSolution.cdsproj --configuration Release
```

or:

```powershell
msbuild ./StatusPickerSolution.cdsproj /restore /p:Configuration=Release
```

Inspect `bin/Release` for ZIP output. Do not infer managed/unmanaged only from the configuration name; inspect `SolutionPackageType` and generated filenames.

When changing a deployed component, increment its manifest version according to the repository's release policy. `pac pcf version` supports manifest, Git tag, and file-tracking strategies.

## Deployment boundary

For an explicitly authorized development environment, fast iteration can use:

```powershell
pac auth create --url https://<org>.crm.dynamics.com
pac org who
pac pcf push --publisher-prefix <prefix> --solution-unique-name <solution>
```

Treat authentication, `pac pcf push`, and solution imports as external mutations. Confirm the exact environment and authorization immediately before execution. Prefer packaged managed solutions and an ALM pipeline for test/UAT/production.

## Official sources

- [Create and build a code component](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/create-custom-controls-using-pcf)
- [Package a code component](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/import-custom-controls)
- [PCF application lifecycle management](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/code-components-alm)
- [PAC CLI `pcf` command group](https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/pcf)
- [PAC CLI `solution` command group](https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/solution)
- [Official PowerApps PCF samples](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework)


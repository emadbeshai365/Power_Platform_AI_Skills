# Packaging and ALM

## Contents

- Build modes versus package types
- Development deployment
- Solution project packaging
- Solution strategy
- Versioning
- CI/CD gates
- Import and upgrade safety
- Official references

## Build modes versus package types

Keep two independent decisions explicit:

| Decision | Controlled by | Values |
| --- | --- | --- |
| PCF bundle optimization | npm `--buildMode production` or `.pcfproj` `PcfBuildMode` | development / production |
| Dataverse solution package type | `.cdsproj` `SolutionPackageType` | Managed / Unmanaged / Both |

`Release` configuration should produce a production PCF build, but it does not by itself prove that the ZIP is managed. Inspect the project setting and generated artifact.

Never deploy a development bundle to a shared or downstream environment. It is larger, slower, and can exceed import limits.

## Development deployment

Use `pac pcf push` for rapid iteration only after explicit authorization:

```powershell
pac auth list
pac org who
pac pcf push --publisher-prefix <prefix> --solution-unique-name <dev-solution>
```

The publisher prefix must match the intended solution publisher. If a production-mode push is required, configure `PcfBuildMode` deliberately; do not assume the default push is production optimized.

State the environment URL immediately before running a mutating command.

## Solution project packaging

Create a segmented solution project when one or more PCF controls need an independently versioned package:

```powershell
mkdir <SolutionFolder>
cd <SolutionFolder>
pac solution init --publisher-name <PublisherName> --publisher-prefix <Prefix>
pac solution add-reference --path <PathToComponentFolderOrPcfproj>
```

Set package type explicitly:

```xml
<PropertyGroup>
  <SolutionPackageType>Both</SolutionPackageType>
</PropertyGroup>
```

Build:

```powershell
dotnet build <Solution>.cdsproj --configuration Release
```

or:

```powershell
msbuild <Solution>.cdsproj /restore /p:Configuration=Release
```

The bundled helper adds production component verification and locates ZIPs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-directory>/scripts/Build-PcfPackage.ps1 `
  -ComponentPath <component-folder> `
  -SolutionPath <solution-folder-or-cdsproj>
```

Verify the `.cdsproj` actually references the intended `.pcfproj` and report every generated ZIP with type, size, and absolute path.

## Solution strategy

### Segmented PCF solution

Use when:

- controls have an independent release cadence;
- multiple maker solutions reuse them;
- a fusion team owns controls separately;
- the component is an internal platform or ISV asset.

Account for downstream solution dependencies and publisher alignment.

### Mixed single solution

Use when:

- the component is inseparable from one app/table solution;
- coordinated app and component releases are preferred;
- avoiding inter-solution dependency management is more important than independent versioning.

In an environment-centric mixed solution workflow, the `.cdsproj` wrapper may not be the system of record for the full solution. Follow the team's unpack/export/pack pipeline.

## Versioning

Track at least:

- control version in `ControlManifest.Input.xml`;
- solution version in solution metadata;
- npm dependency lockfile;
- release artifact/commit identity.

Use `pac pcf version` only with an agreed strategy:

```powershell
pac pcf version --strategy manifest
```

For semantic releases, advance major/minor/patch based on compatibility rather than blindly incrementing patch. A changed namespace/constructor or removed/changed contract property can be breaking.

Canvas apps may require makers to accept an updated code component after deployment. Include that in release notes and verification.

## CI/CD gates

A production pipeline should perform, in order:

1. restore locked npm dependencies;
2. lint and unit tests;
3. manifest/project audit;
4. production PCF build;
5. Release solution build;
6. artifact existence/type verification;
7. optional solution checker and security scanning;
8. publish immutable ZIPs with commit/version metadata;
9. deploy through authorized service connections and environment approvals.

Do not commit `node_modules`, `generated`, `out`, `bin`, `obj`, or generated solution ZIPs unless a repository policy explicitly requires it.

## Import and upgrade safety

Before import:

- confirm environment URL and auth identity;
- confirm managed/unmanaged intent;
- inspect dependencies and publisher;
- verify solution/control version is newer as intended;
- preserve a rollback/redeployment artifact;
- use asynchronous import/polling for automated pipelines where appropriate.

After import:

- publish customizations when the workflow requires it;
- verify the solution and code component versions;
- open the consuming app and test the component;
- confirm canvas makers have updated the component where required;
- verify no unmanaged layer or dependency issue undermines the deployment.

Do not delete auth profiles, clear caches, or import/publish without explicit authorization.

## Official references

- [Package a code component](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/import-custom-controls)
- [PCF application lifecycle management](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/code-components-alm)
- [PAC CLI pcf commands](https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/pcf)
- [PAC CLI solution commands](https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/solution)
- [Managed and unmanaged solutions](https://learn.microsoft.com/en-us/power-platform/alm/solution-concepts-alm)

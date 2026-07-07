# PCF troubleshooting playbook

## Contents

- Diagnose systematically
- Scaffold and tool failures
- Manifest and generated-type failures
- TypeScript and bundle failures
- Harness failures
- Dataset failures
- Push/import/package failures
- Runtime and performance failures

## Diagnose systematically

1. Capture the exact command, working directory, complete first error, and relevant versions.
2. Reproduce with the smallest supported command.
3. Classify the layer: toolchain, project, manifest, TypeScript, bundle, solution, environment, or host runtime.
4. Inspect generated/config files; do not patch output artifacts.
5. Change one cause at a time and rerun the narrowest failing gate.
6. Report the root cause and evidence, not merely the last command that succeeded.

Start with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-directory>/scripts/Test-PcfPrerequisites.ps1 -RequirePac -RequireBuildTool
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-directory>/scripts/Inspect-PcfProject.ps1 -ProjectPath <component-folder>
node --version
npm --version
pac --version
dotnet --version
```

## Scaffold and tool failures

| Symptom | Inspect | Typical resolution |
| --- | --- | --- |
| `pac` not found | PATH and Power Platform Tools/CLI install | Install/update supported PAC CLI; restart terminal. |
| `msbuild` not found | .NET SDK and Visual Studio developer prompt | Use `dotnet build` when supported or a Developer Command Prompt. |
| npm restore fails | Node LTS, registry/proxy, lockfile, certificate | Preserve the lockfile; fix network/toolchain rather than deleting files blindly. |
| old template behavior | `pac --version` | Update PAC and scaffold a comparison project before modifying an established project. |

Do not globally install random PCF build packages to “fix” a template without understanding the repository dependency model.

## Manifest and generated-type failures

### Manifest validation error

- Open `ControlManifest.Input.xml` at the reported node.
- Check element/attribute spelling and nesting against the current schema.
- Check host availability for the element.
- Confirm referenced resources exist with matching case/path.
- Rebuild; never edit generated types.

### `IInputs`/`IOutputs` missing or stale

- Confirm the property exists in the input manifest.
- Confirm `usage` matches intended input/output behavior.
- Run a clean supported build/type refresh.
- Check that imports reference `./generated/ManifestTypes`.
- Remove generated output only if the normal build cannot regenerate it and the repository permits cleanup.

### Standard/React mismatch

- `standard` must implement `StandardControl` and receive a container.
- `virtual` must come from a React template, implement `ReactControl`, and return a React element.
- Do not repair a mismatch by flipping one XML attribute; port through a proper scaffold.

## TypeScript and bundle failures

| Symptom | Likely cause |
| --- | --- |
| Cannot resolve React/Fluent | Template/platform-library/package versions are inconsistent. |
| Bundle unexpectedly huge | Development build, bundled React/Fluent, broad library imports, duplicate dependencies. |
| `ReactDOM.render` issues | Virtual control is using standard-control React mounting. |
| Strict-null errors | Host parameters can be null; code assumed readiness. |
| Listener cleanup does nothing | `.bind()` or arrow function created a different handler reference. |

Use the production build to evaluate bundle output:

```powershell
npm run build -- --buildMode production
```

## Harness failures

### Harness opens but component is blank

- Check browser console and terminal build output.
- Confirm the manifest code resource and constructor/class export.
- Provide required input values and component dimensions.
- Check CSS for zero size/hidden overflow.
- Handle null inputs and loading state.

### Harness works but Dataverse fails

This usually indicates a host dependency:

- API unavailable in the target host;
- missing table/column privileges;
- field security or absent dataset columns;
- navigation/device API difference;
- CSP/external-domain issue;
- solution/publisher/version mismatch;
- canvas component update not accepted.

Reproduce in a minimal authorized development app and inspect browser/network diagnostics.

## Dataset failures

### Missing records or columns

- Read `sortedRecordIds`, not object-key order.
- Inspect view column configuration and dataset columns.
- Account for secured/null fields.
- Check paging and whether the component replaces or appends pages.

### Sorting/filtering loops

- Change sort/filter only on user intent.
- Avoid setting it again on every `updateView`.
- Call refresh only when the API requires it.
- Track in-flight paging/filter operations.

### Slow dataset control

- Reduce rerenders and DOM churn.
- Use stable record IDs and memoized view models.
- Page/virtualize instead of rendering all loaded rows.
- Avoid per-record Web API calls; batch or redesign the data contract.

## Push/import/package failures

### `pac pcf push` targets the wrong environment

Stop. Run `pac auth list` and `pac org who`. Do not retry until the intended URL and identity are confirmed.

### Ambiguous project name

Ensure the solution name and project name are not identical where the tooling rejects ambiguity.

### ZIP is unmanaged when managed was expected

Inspect `.cdsproj` `SolutionPackageType`. Build configuration alone is not the package-type selector.

### Imported component does not update

- Verify control and solution versions.
- Confirm the expected solution layer is active.
- Publish where required.
- For canvas, open the app and accept/update the code component if prompted.
- Clear browser cache only after version/layer checks; cache clearing is not a versioning strategy.

### Solution build succeeds but no ZIP is found

- Inspect actual MSBuild output path and configuration.
- Check `.cdsproj` SDK restore and output settings.
- Confirm a PCF project reference exists.
- Search `bin/<Configuration>` and report actual artifacts.

## Runtime and performance failures

### Repeated network requests

`updateView` is launching work without a key/cache guard. Move one-time work to `init` or cache by the exact dependency set and suppress stale results.

### User input resets while typing

Host value synchronization is overwriting draft state. Separate draft, committed, and last-host values and define a commit event.

### Memory/focus degradation after navigation

Check `destroy` cleanup, handler identity, observers, timers, chart/map/editor disposal, object URLs, and whole-tree rerenders that replace the focused element.

### CSS affects the app

Scope every selector beneath the component root/namespace. Remove global element selectors and framework CSS that is not namespaced.

## Official references

- [Debug code components](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/debugging-custom-controls)
- [Best practices](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/code-components-best-practices)
- [Package a code component](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/import-custom-controls)
- [PAC CLI reference](https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/)

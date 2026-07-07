---
name: build-package-pcf
description: Build, modify, validate, test, and package Microsoft Power Apps Component Framework (PCF) code components using TypeScript, React or standard HTML, Power Platform CLI, npm, and Dataverse solution projects. Use when Codex needs to create or edit field or dataset controls, work with ControlManifest.Input.xml and PCF lifecycle methods, troubleshoot PCF builds, run the local harness, produce production bundles, or package managed/unmanaged solution ZIPs from .pcfproj and .cdsproj projects.
---

# Build and package PCF components

## Start safely

1. Inspect the repository before changing it. Locate `package.json`, `*.pcfproj`, `ControlManifest.Input.xml`, generated manifest types, and any `*.cdsproj`.
2. Preserve the existing package manager, formatting, lint rules, namespace, publisher prefix, component version, and solution layout unless the user requests a change.
3. Determine the component contract before implementation: field or dataset, target hosts, bound/input/output properties, standard HTML or React, external services, and desired package type.
4. For a new component, default to a field control and `--framework react` only when the requested UI benefits from React. Ask only when a wrong choice would materially change the component contract.
5. Never deploy, import, authenticate, or alter a live Dataverse environment without explicit user authorization. Building a local solution ZIP is allowed when requested.

Read [references/pcf-workflow.md](references/pcf-workflow.md) for commands, packaging choices, and official source links. Read [references/implementation-checklist.md](references/implementation-checklist.md) when implementing or reviewing component code.

## Check prerequisites

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/Test-PcfPrerequisites.ps1 -RequirePac -RequireBuildTool
```

Require Node.js LTS, npm, Power Platform CLI (`pac`), and either the .NET SDK or MSBuild. Report missing tools with the official installation path; do not silently install global tools.

## Create a component

Create an empty destination directory, then initialize from that directory:

```powershell
pac pcf init --namespace <Namespace> --name <ComponentName> --template <field|dataset> --framework <none|react> --run-npm-install
```

Follow PAC naming constraints. Do not handcraft the initial `.pcfproj` when PAC is available.

## Implement the component

1. Define the public contract in `ControlManifest.Input.xml` first. Declare every property, dataset, resource, feature, and external service accurately.
2. Regenerate or build after manifest changes so `generated/ManifestTypes.d.ts` stays synchronized. Never edit generated types directly.
3. Implement the appropriate generated interface and lifecycle:
   - Use `init` for one-time setup and asynchronous resource requests.
   - Treat values in `updateView` as temporarily null and render from the current context.
   - Call `notifyOutputChanged` only when outputs actually change.
   - Return only manifest-declared bound/output values from `getOutputs`.
   - Remove listeners, subscriptions, timers, observers, and other resources in `destroy`.
4. Keep DOM and CSS scoped to the component boundary. Do not access host application DOM, `formContext`, or unsupported context members.
5. Check host API availability before use. `context.webAPI`, device APIs, dataset behavior, and Power Pages support vary by host.
6. Declare external domains in `external-service-usage`; explain the premium licensing effect.
7. Implement keyboard access, visible focus, labels/ARIA, responsive sizing, loading/empty/error states, and localization resources.

Use the closest official sample as a pattern, not as a blind template. Keep its license notices when copying Microsoft sample code.

## Validate locally

Run the repository's existing checks first. Typical sequence:

```powershell
npm run lint --if-present
npm run build
npm start watch
```

Use the harness for component behavior, but disclose its limitations: it does not fully reproduce Dataverse, host APIs, or every dataset behavior. Test host-dependent behavior in an authorized development environment.

Fix all build errors and material lint errors. Do not claim runtime verification if only compilation succeeded.

## Package a production solution

If no solution project exists, create a sibling solution directory:

```powershell
pac solution init --publisher-name <PublisherName> --publisher-prefix <Prefix>
pac solution add-reference --path <PathToComponentFolderOrPcfproj>
```

Set `SolutionPackageType` in the `.cdsproj` explicitly to `Managed`, `Unmanaged`, or `Both` based on the requested destination. Use managed for downstream test/UAT/production and unmanaged for a development source environment unless the user specifies otherwise.

Build and locate the package with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/Build-PcfPackage.ps1 -ComponentPath <component-folder> -SolutionPath <solution-folder-or-cdsproj>
```

The script installs locked dependencies when needed, runs available checks, creates a production PCF bundle, builds the solution in Release configuration, and returns generated ZIP paths. Inspect its output and do not report success without an existing ZIP.

## Hand off

Report:

- component type, framework, namespace/name, and changed files;
- validation commands and their actual results;
- package type and absolute ZIP path;
- anything not tested, especially host-specific behavior;
- the next authorized action, such as import or `pac pcf push`, without performing it automatically.

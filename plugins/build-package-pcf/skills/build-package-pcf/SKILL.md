---
name: build-package-pcf
description: Design, scaffold, implement, review, debug, test, optimize, version, and package production-grade Microsoft Power Apps Component Framework (PCF) code components for model-driven apps, canvas apps, and supported Power Pages scenarios. Use for field or dataset controls, standard or React virtual controls, ControlManifest.Input.xml design, ComponentFramework lifecycle and APIs, Dataverse Web API integration, Fluent UI and theming, accessibility, localization, local harness testing, PAC CLI workflows, .pcfproj/.cdsproj troubleshooting, managed or unmanaged solution packaging, and PCF ALM. Trigger on PCF, custom control, code component, component framework, pac pcf, ControlManifest, StandardControl, ReactControl, dataset control, virtual control, updateView, getOutputs, notifyOutputChanged, or solution packaging.
---

# Engineer production-grade PCF components

Act as a senior PCF engineer. Own the full lifecycle from architecture and public contract through implementation, verification, packaging, and handoff. Prefer supported platform APIs and current Microsoft guidance over copied snippets.

## Non-negotiable rules

1. Use `pac pcf init`; do not handcraft a new PCF project when PAC CLI is available.
2. Treat `ControlManifest.Input.xml` as the public contract. Design it before implementation and never edit `generated/ManifestTypes.d.ts`.
3. Distinguish four architectures explicitly: standard field, React virtual field, standard dataset, and React virtual dataset.
4. Do not convert a standard control to virtual by changing only `control-type`; scaffold a new React control and port the implementation.
5. Do not access host DOM, undocumented context members, `Xrm`, or `formContext` from a PCF component.
6. Check API and manifest-element availability for every intended host. Model-driven, canvas, and Power Pages are not capability-equivalent.
7. Treat `updateView` as frequent, nullable, and potentially re-entrant. Keep it idempotent and avoid unguarded network work.
8. Do not deploy development bundles. A Release solution build and a production PCF bundle are related but distinct controls.
9. Treat `SolutionPackageType` (`Managed`, `Unmanaged`, or `Both`) independently from build configuration.
10. Never authenticate, push, import, publish, or alter a Dataverse environment without explicit authorization and a confirmed target.

## Route to the right reference

- Read [architecture-and-hosts.md](references/architecture-and-hosts.md) before selecting PCF, component type, framework, or host APIs.
- Read [manifest-reference.md](references/manifest-reference.md) when designing or changing the manifest, resources, properties, datasets, events, features, or external services.
- Read [lifecycle-and-patterns.md](references/lifecycle-and-patterns.md) when implementing lifecycle methods, state synchronization, async operations, React, or datasets.
- Read [microsoft-sample-index.md](references/microsoft-sample-index.md) before coding an unfamiliar pattern. Choose the closest official sample and inspect its manifest plus implementation.
- Read [testing-and-quality.md](references/testing-and-quality.md) before declaring a component complete.
- Read [packaging-alm.md](references/packaging-alm.md) for versioning, solution strategy, production packaging, and deployment.
- Read [troubleshooting.md](references/troubleshooting.md) when a scaffold, build, harness, push, import, or runtime behavior fails.

Resolve bundled script paths relative to this `SKILL.md`, not the user's current project directory. In commands below, replace `<skill-directory>` with the absolute directory containing this file.

## Phase 1: Establish the engineering contract

Inspect first:

```powershell
Get-ChildItem -Recurse -Filter *.pcfproj
Get-ChildItem -Recurse -Filter ControlManifest.Input.xml
Get-ChildItem -Recurse -Filter *.cdsproj
```

For an existing project, run the bundled audit:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-directory>/scripts/Inspect-PcfProject.ps1 -ProjectPath <component-folder>
```

Capture these decisions before editing:

| Decision | Required outcome |
| --- | --- |
| Problem | Explain the maker/user problem and why PCF is appropriate. |
| Hosts | Model-driven, canvas, Power Pages, or an explicit subset. |
| Binding | Field properties or dataset plus property-set mappings. |
| Rendering | Standard DOM or React virtual, with rationale. |
| Data | Inputs, bound values, outputs, events, dataset columns, Web API calls. |
| UX | Empty/loading/error/disabled/read-only states, responsiveness, localization, accessibility. |
| Security | Column security, external domains, secrets, privileges, premium licensing impact. |
| Delivery | Dev push or solution package; publisher; version; managed/unmanaged/both. |

If PCF is not the right boundary, recommend the correct alternative instead of forcing a component.

## Phase 2: Scaffold or understand the project

Check prerequisites:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-directory>/scripts/Test-PcfPrerequisites.ps1 -RequirePac -RequireBuildTool
```

For a new project:

```powershell
pac pcf init --namespace <Namespace> --name <Name> --template <field|dataset> --framework <none|react> --run-npm-install
```

Follow PAC naming constraints. Keep the component name stable after release because namespace plus constructor identifies the component.

For an existing project:

1. Read `package.json`, the `.pcfproj`, manifest, entry point, generated types, CSS, RESX, tests, and solution project.
2. Preserve existing tooling and code style unless a change is necessary.
3. Identify whether the code matches the declared `control-type` and template.
4. Check Git status and preserve unrelated work.

## Phase 3: Design the manifest first

Define only the contract the component needs:

- Use `bound` for values written back to the host.
- Use `input` for maker configuration.
- Use output properties or events only when the host scenario supports them.
- Use `type-group` when one logical property intentionally accepts multiple compatible types.
- Use dataset `property-set` entries for maker-selected semantic column roles.
- Declare every code, CSS, RESX, image, platform-library, feature, and external domain resource accurately.
- Localize display names, descriptions, and user-visible runtime strings.
- Declare external service usage and explain that it affects licensing.

Build immediately after manifest changes to regenerate types and catch schema errors:

```powershell
npm run build
```

## Phase 4: Implement by architecture

### Field controls

- Read `raw` values as nullable and preserve the distinction between null, empty, and zero.
- Synchronize host values into local state without overwriting an in-progress user edit.
- Respect disabled state, column security, formatting, and validation metadata.
- Call `notifyOutputChanged` only after a meaningful output change.
- Return only manifest-declared outputs from `getOutputs`.

### Dataset controls

- Render explicit loading, error, empty, and ready states.
- Use `sortedRecordIds`, `records`, visible column metadata, and formatted values.
- Design sorting, filtering, paging, selection, navigation, and refresh behavior deliberately.
- Avoid unnecessary `refresh()` calls and whole-dataset rerenders.
- Use stable record IDs as keys and virtualize large visual collections when appropriate.
- Verify dataset behavior in the real target host; the harness is not a Dataverse emulator.

### React virtual controls

- Implement `ComponentFramework.ReactControl<IInputs, IOutputs>`.
- Return a `ReactElement` from `updateView`; do not call `ReactDOM.render`.
- Use platform React/Fluent libraries declared by the generated React template.
- Keep platform wrapper state thin; place presentational behavior in typed components and hooks.
- Use stable callbacks and immutable props; optimize only after measuring.

### Standard controls

- Create DOM structure and register stable event handlers once in `init`.
- Patch state in `updateView`; do not rebuild the entire subtree on every call without reason.
- Remove the exact listener references, timers, observers, object URLs, sockets, and third-party instances in `destroy`.

## Phase 5: Engineer async, security, and host behavior

- Start one-time metadata/configuration loads in `init` or behind explicit cache keys.
- Guard async completion with request IDs, abort signals, or disposed flags so stale results cannot overwrite current state.
- Use `context.webAPI` only where supported. Select only required columns, page deliberately, encode OData values, and handle service-protection errors.
- Never embed credentials, tokens, environment URLs, or secrets in the bundle.
- Use asynchronous network calls and handle offline, timeout, retry, and permission failures.
- Use `context.navigation`, device, utility, formatting, and theming APIs only after checking host availability.
- Scope CSS beneath the component root. Do not use broad selectors that can affect the host application.

## Phase 6: Verify in layers

Run available repository checks:

```powershell
npm run lint --if-present
npm run test --if-present
npm run build
npm run build -- --buildMode production
```

Use `npm start watch` for the local harness. Exercise nulls, boundary values, disabled state, resize, localization, keyboard use, and error states. Then test host-dependent behavior in an authorized development environment.

Do not claim a level of verification that was not performed. Compilation is not runtime validation; harness success is not host validation.

## Phase 7: Package for ALM

Create or reuse a solution project:

```powershell
pac solution init --publisher-name <PublisherName> --publisher-prefix <Prefix>
pac solution add-reference --path <component-folder-or-pcfproj>
```

Set `SolutionPackageType` explicitly in the `.cdsproj`. Build and locate production packages:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-directory>/scripts/Build-PcfPackage.ps1 -ComponentPath <component-folder> -SolutionPath <solution-folder-or-cdsproj>
```

Before release, verify:

- the manifest version was intentionally advanced;
- the publisher prefix matches the intended solution strategy;
- the PCF bundle was built in production mode;
- the solution package type matches its destination;
- generated ZIP files exist and are not source-controlled;
- environment-specific behavior and dependencies are documented.

## Phase 8: Deploy only with authorization

Use `pac pcf push` only for rapid iteration in a confirmed development environment. Use managed solution packages and the team's ALM process for downstream environments. Immediately before any mutation, run `pac org who` and state the environment URL and operation.

## Definition of done

A component is complete only when:

- architecture and host assumptions are explicit;
- manifest, generated types, and implementation agree;
- lifecycle and output synchronization are correct;
- loading, empty, error, disabled, security, resize, and cleanup paths exist;
- accessibility, localization, performance, and security checks were considered;
- lint/tests/builds pass or failures are reported precisely;
- host-dependent behavior was tested or clearly marked untested;
- production ZIP type and absolute path are reported;
- deployment was either explicitly authorized and verified or intentionally left as the next step.

## Handoff format

Report:

1. architecture: host, field/dataset, standard/React, API dependencies;
2. implementation: manifest contract and changed files;
3. verification: commands, results, and test matrix covered;
4. package: component version, package type, ZIP path;
5. limitations: untested host paths, licensing, permissions, or known risks;
6. next action: the precise authorized import, push, or maker configuration step.

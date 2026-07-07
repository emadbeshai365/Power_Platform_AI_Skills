# Testing and quality gates

## Contents

- Verification layers
- Static and build gates
- Unit-test seams
- Harness test matrix
- Target-host validation
- Accessibility
- Performance
- Security and dependency review
- Release evidence

## Verification layers

Never collapse these into one claim:

| Layer | Proves | Does not prove |
| --- | --- | --- |
| XML/project audit | Files and manifest contract are internally coherent. | TypeScript compiles or behavior works. |
| Lint/type/build | Source compiles and bundle generation succeeds. | Runtime behavior or host API availability. |
| Unit tests | Pure state transformations and services behave for covered cases. | PCF host integration. |
| Local harness | Basic lifecycle, properties, rendering, resize, and interaction. | Dataverse security, all dataset behavior, navigation/device/Web API parity. |
| Development host | Real model-driven/canvas/Power Pages integration. | Production ALM and performance at scale. |
| Packaged import | Solution artifact imports and component metadata is valid. | Every consuming app is configured correctly. |

## Static and build gates

Run the project audit before and after substantial changes:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-directory>/scripts/Inspect-PcfProject.ps1 -ProjectPath <component-folder>
```

Then run defined scripts rather than inventing replacements:

```powershell
npm ci
npm run lint --if-present
npm run test --if-present
npm run build
npm run build -- --buildMode production
```

Use `npm ci` when a committed lockfile exists. Do not silently rewrite the lockfile during verification.

Review bundle warnings, dependency vulnerabilities, deprecated APIs, and output size. A successful exit code with serious warnings is not a clean gate.

## Unit-test seams

Keep platform wrappers thin so these behaviors can be tested without a PCF host:

- raw-to-view-model mapping;
- view-model-to-output mapping;
- null/empty/zero and choice/lookup conversions;
- dataset record/column projection;
- sorting/filter specification construction;
- output commit/debounce rules;
- async cache and stale-result suppression;
- error normalization;
- accessibility labels and state messages.

Mock only the narrow context members used by a service. Avoid a giant untyped fake `Context` that makes tests pass while hiding API mistakes.

## Harness test matrix

Use `npm start watch` and exercise:

### Inputs and outputs

- null/undefined/empty values;
- minimum, maximum, and invalid values;
- host update after a local commit;
- local edit while a host update arrives;
- multiple component instances;
- output clear/reset behavior.

### Lifecycle and layout

- first render and repeated `updateView` calls;
- disabled/read-only state;
- narrow, wide, short, and unconstrained containers;
- visibility changes when observable;
- destroy/remount and listener cleanup.

### Dataset

- loading, error, empty, and populated states;
- missing or reordered columns;
- null/secured values;
- sort/filter transitions;
- first, middle, and last pages;
- repeated next-page actions;
- selection and record navigation.

### Localization and formatting

- long translated labels;
- right-to-left layout when required;
- date/number/currency formatting;
- timezone-sensitive values.

Record harness limitations in the handoff.

## Target-host validation

Use an explicitly authorized development environment and test every promised host separately.

### Model-driven

- main form, quick-create or supported form surface as applicable;
- main grid, view, subgrid, or dashboard for dataset controls;
- field-level security and privileges;
- save/refresh/navigation cycles;
- Web API and navigation operations;
- app theme and high-contrast mode.

### Canvas

- responsive containers and formula-bound inputs/outputs;
- behavior across Studio and published player;
- events/object outputs where used;
- app theming and multiple control instances;
- component feature enablement and security warning flow.

### Power Pages

- supported field scenario and web client;
- documented feature restrictions;
- authentication/permissions and portal data surface;
- no reliance on React virtual control parity.

## Accessibility

- Use semantic elements before ARIA repair.
- Provide programmatic name, role, value, state, and error association.
- Support keyboard-only operation and logical focus order.
- Keep visible focus indicators.
- Do not encode state by color alone.
- Announce asynchronous loading, completion, and errors where needed.
- Meet contrast and target-size expectations.
- Test zoom/reflow and high contrast.
- Avoid focus loss during `updateView` rerenders.

## Performance

- Keep `updateView` fast and idempotent.
- Render only when relevant values changed.
- Avoid repeated metadata/Web API requests.
- Select only required Dataverse columns.
- Page/virtualize large datasets.
- Use platform React/Fluent libraries for virtual controls.
- Measure production bundles, not only development bundles.
- Dispose charts, maps, editors, observers, and object URLs.
- Test multiple instances on one form/screen.

## Security and dependency review

- No credentials, tokens, environment URLs, or secrets in source/manifest/bundle.
- No unsupported host DOM or internal APIs.
- External domains declared and justified.
- User content encoded or sanitized.
- OData/query input encoded and constrained.
- Dataverse privileges and column security failures handled.
- Third-party licenses and maintenance state reviewed.
- Dependency audit findings triaged, not blindly auto-fixed.
- CSP/iframe/external-content behavior verified for the target host.

## Release evidence

Hand off a compact evidence table:

| Gate | Command/environment | Result | Notes |
| --- | --- | --- | --- |
| Project audit | `Inspect-PcfProject.ps1` | Pass/fail | Warnings. |
| Lint | Repository command | Pass/fail/not present |  |
| Unit tests | Repository command | Pass/fail/not present | Coverage focus. |
| Development build | `npm run build` | Pass/fail |  |
| Production build | `npm run build -- --buildMode production` | Pass/fail | Bundle notes. |
| Harness | Local | Pass/partial/not run | Scenarios. |
| Host | Environment and app type | Pass/partial/not run | Do not expose secrets. |
| Package | `.cdsproj` Release | Pass/fail | Managed/unmanaged/both and ZIP. |

## Official references

- [Debug code components](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/debugging-custom-controls)
- [Best practices](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/code-components-best-practices)
- [PCF application lifecycle management](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/code-components-alm)

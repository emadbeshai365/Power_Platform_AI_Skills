# PCF implementation checklist

## Contents

- Manifest
- Lifecycle and state
- Field controls
- Dataset controls
- React controls
- Quality and security
- Sample selection

## Manifest

- Keep namespace and constructor stable after release.
- Use clear localized display-name and description keys.
- Mark each property accurately as `input`, `bound`, or `output`.
- Match `of-type` or `of-type-group` to supported Dataverse values.
- Register every code, CSS, and `.resx` resource with deterministic ordering.
- Declare required `<feature-usage>` entries and verify host support.
- Declare all directly contacted external domains in `<external-service-usage enabled="true">`; such components are premium.
- Increment the control version for distributable updates.

Consult the [manifest schema reference](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/manifest-schema-reference/) rather than guessing element names.

## Lifecycle and state

- `init`: retain callbacks/container references, attach one-time listeners, request asynchronous metadata, and request resize tracking when needed. Do not assume dataset values are ready.
- `updateView`: treat raw values as nullable; use `context.updatedProperties` when it safely avoids unnecessary work; synchronize disabled, visible, size, validation, and loading states.
- `notifyOutputChanged`: call after a meaningful output change, not every keypress unless live updates are an explicit requirement.
- `getOutputs`: return only the current manifest-declared outputs.
- `destroy`: cancel requests where possible and remove listeners, timers, observers, subscriptions, sockets, and mounted UI.

## Field controls

- Preserve null versus empty values intentionally.
- Respect `context.mode.isControlDisabled`.
- Avoid feedback loops between `updateView`, local state, and `notifyOutputChanged`.
- Use platform formatting APIs for dates, numbers, and currency when appropriate.
- Show framework validation errors without overwriting unrelated styles.

## Dataset controls

- Handle loading, empty, error, paging, sorting, filtering, selection, and refresh states.
- Do not call dataset `refresh()` unnecessarily.
- Use record IDs as stable keys.
- Avoid rendering the entire record set when paging or virtualization is appropriate.
- Verify dataset behavior in the actual target host; the local harness is incomplete.

## React controls

- For a virtual React control, implement `ComponentFramework.ReactControl<IInputs, IOutputs>` and return a `ReactElement` from `updateView`.
- Keep props immutable and callbacks stable where practical.
- Use memoization only when measurements show value.
- Prefer platform React/Fluent libraries supported by the selected PCF template and avoid bundling duplicate framework versions.
- For legacy standard controls that mount React manually, unmount during `destroy`.

## Quality and security

- Scope CSS beneath the component's generated root class.
- Never inspect or mutate host DOM outside the supplied container.
- Never use undocumented `context` APIs or depend directly on `formContext`.
- Bundle dependencies; do not inject remote `<script>` tags.
- Avoid `localStorage` and `sessionStorage` for component data.
- Use asynchronous network calls, minimal payloads, error/timeout handling, and no embedded secrets.
- Provide keyboard navigation, semantic controls, visible focus, labels, accessible names, and screen-reader announcements for dynamic state.
- Test responsive widths/heights and call `trackContainerResize` only when required.
- Localize user-visible text with `.resx` resources.
- Run production build, lint, relevant tests, and dependency/security review before packaging.

See [Microsoft PCF best practices](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/code-components-best-practices).

## Sample selection

Start from the closest official sample under [PowerApps-Samples/component-framework](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework):

- `IncrementControl` or `LinearInputControl`: basic bound field and outputs.
- `ReactStandardControl`: React hosted by a standard control.
- `DataSetGrid`, `CanvasGridControl`, or `ModelDrivenGridControl`: dataset behavior by host.
- `WebAPIControl`: Dataverse Web API patterns for supported hosts.
- `LocalizationAPIControl`: localized resources.
- `FormattingAPIControl`: platform formatting.
- `ControlStateAPI`: session control state.

Copy only what the task needs and preserve Microsoft sample license headers.


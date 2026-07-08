# Advanced component patterns

## Contents

- Object outputs and dynamic schemas
- Custom events
- Advanced datasets
- Power Apps grid customizers
- Fluent v9 theming
- Files, images, lookups, linking, and popups
- Pattern acceptance checklist
- Official references

## Object outputs and dynamic schemas

Use an `Object` output when the component must expose a structured value rather than unrelated scalar outputs.

1. Define the output property with `of-type="Object"` and `usage="output"`.
2. Define the object shape before implementation. Keep it small, stable, serializable, and free of functions or cyclic values.
3. Implement `getOutputSchema(context)` because the framework calls it before component initialization.
4. Return a schema entry for every Object output. Use only the JSON Schema subset supported by Microsoft: object/properties, array/items, string, number, integer, and boolean.
5. For Canvas, add the hidden schema input and `property-dependencies` required by the current Object Output sample.
6. Call `notifyOutputChanged` only when the semantic object changes. Return the current object from `getOutputs`.
7. Test null/empty semantics and the consuming Power Fx or model-driven client code.

Do not return Dataverse response objects, framework objects, class instances, secrets, or unbounded record collections.

## Custom events

Custom events are currently documented as pre-release. Require explicit acceptance before selecting them for production.

1. Add localized `<event>` nodes to the manifest.
2. Build to regenerate event types.
3. Raise the generated `context.events.<eventName>()` callback only for an intentional user/domain action.
4. For Canvas, document the Power Fx formula configured on each event.
5. For model-driven apps, document registration/removal using the supported control event-handler APIs.
6. Define event ordering, re-entrancy, duplicate suppression, error behavior, and payload strategy.
7. Test multiple component instances and rapid activation.

Do not use events as a substitute for bound outputs. Use an output for state and an event for occurrence/intent.

## Advanced datasets

Design dataset behavior as a state machine:

- `loading`: initial or explicit refresh;
- `ready`: records and column metadata are available;
- `empty`: request succeeded with no records;
- `error`: permission, throttling, network, or query failure;
- `paging`: preserve current rows while preventing overlapping requests.

Engineering rules:

- Render in `sortedRecordIds` order and use stable record IDs as keys.
- Read formatted values for display and raw values for logic.
- Keep selected record IDs synchronized with the dataset selection API.
- Guard `loadNextPage`/`loadPreviousPage` calls and do not infer total count from the current page.
- Treat filtering, sorting, and refresh as host-owned operations that can trigger `updateView` repeatedly.
- Confirm command visibility, view selector, property-set columns, linked tables, and target entity type in the real model-driven host.
- Virtualize large visual lists and avoid per-cell Web API calls.
- Preserve column-security and missing-column behavior.

## Power Apps grid customizers

Use the official `GridCustomizerControlTemplate`; it is a specialized React virtual control, not a normal dataset replacement.

- Implement `CellRendererOverrides` for read-only cells and `CellEditorOverrides` for edit mode.
- Return `null`/`undefined` to fall back to the platform renderer/editor.
- Keep override functions pure, deterministic, lightweight, and accessible.
- Do not mutate grid data or metadata from a renderer.
- Do not visually replace values in a way that disagrees with server-side sort/filter semantics.
- Dispose editor state on unmount and expect the grid to recreate cells at any time.
- Test keyboard editing, validation, high contrast, row virtualization, and multiple column types.

## Fluent v9 theming

For React virtual controls, use the platform React and Fluent libraries from a current PAC scaffold.

1. Read `context.fluentDesignLanguage` when available.
2. Pass platform tokens through `FluentProvider`; do not hard-code brand colors as the primary theme.
3. Respond to light/dark and theme changes during `updateView`.
4. Use semantic Fluent tokens for foregrounds, backgrounds, borders, status, typography, spacing, and focus.
5. Keep a tested fallback theme for hosts that do not expose modern theming.
6. Verify high contrast independently; dark mode alone is not an accessibility test.

## Files, images, lookups, linking, and popups

### Files and images

- Validate type, extension, MIME, and size before processing.
- Handle cancellation and partial failures.
- Revoke object URLs in `destroy` or component cleanup.
- Avoid loading large files fully into memory when the API offers chunking.
- Never infer trust from a file extension or render unsanitized SVG/HTML.

### Lookups and linking

- Use supported lookup values and metadata; do not query host DOM or form internals.
- Treat linking/linked-table APIs as model-driven-specific unless the current API page says otherwise.
- Handle unavailable targets, privileges, and deleted records.

### PopupService and Factory

- Check method-level availability.
- Create, open, update, close, and delete popups through the supported service.
- Keep focus trapping, Escape behavior, accessible naming, and cleanup correct.
- Do not make popup availability a hidden requirement for hosts without that service.

## Pattern acceptance checklist

- Manifest and generated types represent the intended contract.
- Feature status is labeled GA, preview, deprecated, or unsupported.
- Every promised host has an availability decision and test case.
- Output/event semantics are documented for makers and developers.
- Async and cleanup paths are covered.
- Accessibility, localization, security, and performance are tested.
- The closest Microsoft sample is cited, but its demo shortcuts are not copied blindly.

## Official references

- [StandardControl.getOutputSchema](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/reference/control/getoutputschema)
- [Object Output component sample](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/sample-controls/object-output)
- [Property dependencies](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/manifest-schema-reference/property-dependencies)
- [Define a custom event](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/tutorial-define-event)
- [Customize the editable grid control](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/customize-editable-grid-control)
- [Theming API](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/reference/theming)
- [PopupService](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/reference/popupservice)

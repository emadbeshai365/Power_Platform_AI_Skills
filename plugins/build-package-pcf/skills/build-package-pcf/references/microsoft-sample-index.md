# Microsoft PCF sample index

> Source snapshot: reviewed 2026-07-08 against Microsoft `PowerApps-Samples` commit `27394f76c38a2c3fad24b5d705e92a3c4850db8e`. Refresh using [ci-and-governance.md](ci-and-governance.md).

## Contents

- How to use this index
- Architecture and UI samples
- Field and type samples
- Dataset and grid samples
- Platform API samples
- Advanced and specialized samples
- Sample review method

## How to use this index

Use Microsoft's [PowerApps-Samples/component-framework](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework) repository as the primary implementation corpus.

1. Select the closest sample by architecture and API, not visual resemblance alone.
2. Read its `README.md`, `ControlManifest.Input.xml`, `.pcfproj`, `package.json`, entry point, generated-type usage, CSS/RESX, and solution project.
3. Compare it with current Microsoft documentation because samples can preserve older libraries or patterns.
4. Copy the smallest relevant pattern and retain Microsoft license headers on copied sample code.
5. Do not assume a sample supports every host; honor its compatibility statement and current API availability.

## Architecture and UI samples

| Sample | Architecture/host | Use it to learn | Cautions |
| --- | --- | --- | --- |
| [IncrementControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/IncrementControl) | Standard field; model-driven and canvas | Minimal bound-value flow, `notifyOutputChanged`, `getOutputs`. | Educational simplicity; strengthen cleanup, null handling, and accessibility. |
| [LinearInputControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/LinearInputControl) | Standard numeric field; model-driven and canvas | Numeric type groups, slider interaction, value binding. | Validate current input semantics and keyboard/accessibility behavior. |
| [ReactStandardControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/ReactStandardControl) | Standard control manually hosting React | Legacy/manual React mounting inside `StandardControl`. | Prefer a React virtual control for new complex model-driven/canvas UI. |
| [FacepileReactControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/FacepileReactControl) | React virtual; model-driven and canvas | `ReactControl`, platform-hosted React, virtual rendering. | Check current Fluent package/version guidance. |
| [ChoicesPickerReactControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/ChoicesPickerReactControl) | React virtual field; model-driven | Converting a field experience to virtual React, metadata/security-aware choices. | Do not “convert” by editing only the manifest. |
| [FluentThemingAPIControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/FluentThemingAPIControl) | React virtual; model-driven and canvas | Current app theming and Fluent-aligned component styling. | Theme APIs and modern-theme behavior are host/version sensitive. |
| [AngularJSFlipControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/AngularJSFlipControl) | Standard; third-party AngularJS; both app types | How a third-party library can be bundled. | Legacy AngularJS/Bootstrap sample; not a recommended new-project architecture. |

## Field and type samples

| Sample | Architecture/host | Use it to learn | Cautions |
| --- | --- | --- | --- |
| [ChoicesPickerControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/ChoicesPickerControl) | Standard field; model-driven | Choice metadata, icons, column-level security. | Model-driven-specific metadata behavior. |
| [MultiSelectOptionSetControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/MultiSelectOptionSetControl) | Standard field; model-driven | `MultiSelectOptionSet` binding and output conversion. | Test null/empty arrays and current type support. |
| [LookupSimpleControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/LookupSimpleControl) | Standard multi-lookup field; model-driven | `Lookup.Simple`, multiple bound lookups, `lookupObjects`. | Utility/navigation APIs are host-specific. |
| [IFrameControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/IFrameControl) | Standard multi-property field; both app types | Binding multiple form columns as component inputs. | Validate URLs, CSP, origin, and external-content security. |
| [MapControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/MapControl) | Standard multi-property field; both app types | Combining address properties into a visualization. | External map service licensing, keys, domains, CSP, and privacy require redesign. |
| [ImageUploadControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/ImageUploadControl) | Standard field; both app types | `Device.pickFile`, preview/reset interaction. | Validate file size/type, object URL cleanup, and real Dataverse upload strategy. |
| [ObjectOutputControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/ObjectOutputControl) | React virtual; model-driven and canvas | Object output, hidden schema input, `property-dependencies`, `getOutputSchema`. | Pre-release sample; validate schema subset and maker consumption semantics. |

## Dataset and grid samples

| Sample | Architecture/host | Use it to learn | Cautions |
| --- | --- | --- | --- |
| [DataSetGrid](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/DataSetGrid) | Standard dataset; model-driven | Tile rendering, record collection interaction. | Extend with robust paging, selection, and accessibility. |
| [TableGrid](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/TableGrid) | Standard dataset; model-driven | Column metadata, record binding, paging, record navigation. | Educational DOM grid; not a full enterprise grid. |
| [ModelDrivenGridControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/ModelDrivenGridControl) | Standard dataset; model-driven-focused, documented compatibility includes canvas | Paged/scrollable grid, sort/filter, configurable indicator column. | Verify exact host behavior and dataset APIs used. |
| [CanvasGridControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/CanvasGridControl) | Standard dataset; canvas | Canvas dataset grid, paging, sort/filter, row highlighting. | Canvas-specific configuration and testing required. |
| [PropertySetTableControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/PropertySetTableControl) | Standard dataset; canvas | Property-set column mapping, metadata, paging, navigation. | Treat property-set availability as host-specific. |
| [PowerAppsGridCustomizerControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/PowerAppsGridCustomizerControl) | React virtual grid customizer; model-driven | Customize editable grid cell rendering/behavior. | This is a grid customizer pattern, not a generic dataset replacement. |
| [resources/GridCustomizerControlTemplate](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/resources/GridCustomizerControlTemplate) | React virtual template | Baseline structure for grid customizer controls. | Use with the editable-grid customization documentation. |

## Platform API samples

| Sample | Architecture/host | Use it to learn | Cautions |
| --- | --- | --- | --- |
| [ControlStateAPI](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/ControlStateAPI) | Standard; both app types | Persist same-session UI state with control state API. | Not durable storage; do not store secrets. |
| [DeviceApiControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/DeviceApiControl) | Standard; both app types | Camera, location, file, barcode/device capabilities. | Declare features and test permission denial/device availability. |
| [FormattingAPIControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/FormattingAPIControl) | Standard; both app types | Platform number/date formatting APIs. | Use current locale/timezone behavior and null handling. |
| [LocalizationAPIControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/LocalizationAPIControl) | Standard; both app types | RESX localization and `context.resources`. | Test long strings, missing keys, RTL, and fallback. |
| [NavigationAPIControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/NavigationAPIControl) | Standard; model-driven | Alert/confirm/error dialogs, URL/form navigation methods. | Navigation methods have host availability differences. |
| [TableControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/TableControl) | Standard; model-driven | Inspecting context/user/client/device/utility APIs in a table. | Diagnostic sample; do not expose sensitive context details in production. |
| [WebAPIControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/WebAPIControl) | Standard; model-driven | Dataverse CRUD through `context.webAPI`. | Add least-privilege queries, robust errors, concurrency, and loading states. |

## Advanced and specialized samples

| Sample | Architecture/host | Use it to learn | Cautions |
| --- | --- | --- | --- |
| [CodeInterpreterControl](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework/CodeInterpreterControl) | Standard; model-driven with AI capabilities | Rendering Code Interpreter prompt outputs, interactive HTML, previews/downloads. | Specialized AI/environment prerequisites; treat generated HTML/files as untrusted content. |

## Pattern routing

| Requirement | Start with |
| --- | --- |
| Simple field input/output | `IncrementControl`, then strengthen with this skill's lifecycle checklist. |
| Numeric slider or compatible numeric types | `LinearInputControl`. |
| New Fluent/React field experience | `ChoicesPickerReactControl` or `FacepileReactControl`. |
| Choice metadata/security | `ChoicesPickerControl` and its React counterpart. |
| Lookup picker | `LookupSimpleControl`. |
| Multi-select choice | `MultiSelectOptionSetControl`. |
| Canvas dataset with semantic column mappings | `PropertySetTableControl`. |
| Model-driven grid/table | `TableGrid` then `ModelDrivenGridControl`. |
| Editable grid cell customization | `PowerAppsGridCustomizerControl` plus template. |
| Device/camera/file/location | `DeviceApiControl`; use `ImageUploadControl` for picker UX. |
| Dataverse CRUD | `WebAPIControl`. |
| Formatting/localization | `FormattingAPIControl`, `LocalizationAPIControl`. |
| Session UI persistence | `ControlStateAPI`. |
| Object outputs | `ObjectOutputControl`. |
| Modern theming | `FluentThemingAPIControl`. |

## Sample review method

For the chosen sample, produce a short extraction note:

```text
Sample:
Why it matches:
Host compatibility:
Manifest elements to reuse:
Lifecycle/API pattern to reuse:
Patterns that are legacy or educational only:
Changes required for this component:
```

Never transplant a sample's namespace, publisher, versions, table names, CSS scope, or security assumptions.

## Official references

- [All official PCF samples](https://github.com/microsoft/PowerApps-Samples/tree/master/component-framework)
- [Create and build a component](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/create-custom-controls-using-pcf)
- [PCF tutorials and samples](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/tutorial-create-model-driven-app-component)
- [Best practices](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/code-components-best-practices)

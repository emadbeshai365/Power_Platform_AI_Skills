# Architecture and host selection

## Contents

- Choose PCF or another extension point
- Choose field or dataset
- Choose standard or React virtual
- Define the host matrix
- Define the component contract
- Security and licensing boundary
- Official references

## Choose PCF or another extension point

Use PCF when the experience must participate in the Power Apps component lifecycle, bind to a field or dataset, expose maker-configurable properties, and render inside supported app surfaces.

| Requirement | Prefer | Why |
| --- | --- | --- |
| Replace a field editor or visualization | PCF field control | Typed field binding and form-save integration. |
| Replace a view/subgrid representation | PCF dataset control | Dataset metadata, records, sorting, filtering, paging, and navigation. |
| Add a command bar action | Modern commanding or ribbon customization | PCF is not a command bar extension point. |
| Coordinate visibility/requiredness across form fields | Form script or business rule | PCF must not depend on `formContext` or manipulate other host controls. |
| Build a full-page workflow | Custom page, canvas page, or code app | PCF should remain a focused component boundary. |
| Render standalone HTML content | Web resource when appropriate | No field/dataset lifecycle is required. |
| Apply simple display formatting | Native control, Power Fx, or column formatting | Avoid code and deployment when configuration is sufficient. |

Do not choose PCF merely because it can render HTML. State what platform lifecycle, binding, or API capability makes PCF the right boundary.

## Choose field or dataset

### Field control

Choose a field control when the primary contract is one or more scalar/lookup/choice values. Typical examples include sliders, ratings, pickers, formatted values, maps driven by address fields, and multi-property visualizations.

Design questions:

- Which property is bound and written back?
- Which properties are maker inputs only?
- Are multiple bound fields required?
- How are null, empty, invalid, and secured values represented?
- Should output update live, on blur, or on explicit commit?

### Dataset control

Choose a dataset control when the primary contract is a configurable record collection. Typical examples include grids, cards, galleries, kanban boards, calendars, and record selectors.

Design questions:

- Which semantic column roles need `property-set` mappings?
- Who owns sorting/filtering: maker view, user interaction, or component?
- What is the paging strategy?
- Is selection an output, navigation action, or local state?
- What happens when columns are missing, secured, or null?
- Can the UI handle thousands of records through paging/virtualization?

## Choose standard or React virtual

| Standard control | React virtual control |
| --- | --- |
| Receives a DOM container in `init`. | Does not receive a DOM container. |
| `updateView` returns `void`. | `updateView` returns a `ReactElement`. |
| Component owns DOM/event cleanup. | Platform owns the React render tree. |
| Suitable for small native DOM controls or required Power Pages support. | Suitable for substantial interactive UI in model-driven/canvas apps. |
| May host React manually, but bundles/rendering are component-owned. | Reuses platform React/Fluent libraries and reduces bundle duplication. |

Prefer React virtual for new, nontrivial model-driven/canvas UI. Prefer standard when direct DOM is genuinely simpler or the target includes Power Pages. Microsoft states React virtual controls/platform libraries are not supported for Power Pages; apply the complete gate in [power-pages-compatibility.md](power-pages-compatibility.md), not only a rendering check.

Do not change only `control-type="standard"` to `virtual`. Microsoft explicitly requires creating a new React-template control and porting the manifest and implementation.

## Define the host matrix

Treat availability as a per-API and per-manifest-element question, not a blanket “PCF supports this host” statement.

| Concern | Model-driven | Canvas | Power Pages |
| --- | --- | --- | --- |
| Standard field controls | Supported | Supported | Supported with documented limitations. |
| React virtual/platform libraries | Supported | Supported | Not supported as an equivalent reactive experience. |
| Dataset behavior | Strong model-driven support | Supported patterns differ; validate component and feature | Do not promise general dataset support. |
| `context.webAPI` | Available | Do not assume availability; verify current API reference | Host-specific restrictions. |
| Navigation/device/utility APIs | Per-method availability | Per-method availability | Subset only. |
| Manifest elements | Per-element availability | Per-element availability | Restricted field scenario; apply the mandatory Pages rejection checks. |

For each used API, open its Microsoft API reference and record “Available for.” For each manifest element, check the manifest schema reference. If a task spans hosts, implement capability checks and graceful degradation.

## Define the component contract

Write a short component ADR before code:

```text
Problem:
Why PCF:
Target hosts:
Template: field | dataset
Rendering: standard | react
Bound inputs/outputs:
Maker inputs:
Events:
Dataset property sets:
Platform APIs:
External services:
State model:
Accessibility/localization:
Packaging strategy:
```

Make state ownership explicit:

- Host state: manifest parameters and dataset.
- Committed output state: what `getOutputs` returns.
- Draft interaction state: text being edited, open panels, current selection.
- Session state: values intentionally persisted through `setControlState`.
- Remote state: Web API or external service data with loading/error/staleness rules.

## Security and licensing boundary

- Respect field security metadata and disabled/read-only state.
- Never bundle secrets; PCF code executes in the client.
- Use least-privilege Dataverse operations and request only needed columns.
- Treat direct external-service calls as a licensing and security decision. Declare domains with `external-service-usage` where supported and explain the premium impact.
- Validate URLs and untrusted strings. Prefer text APIs over injecting HTML; sanitize any intentionally rendered HTML.
- Do not use `localStorage` or `sessionStorage` for component data or credentials.
- Do not inspect or mutate host DOM outside the supplied container.

## Official references

- [PCF overview](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/overview)
- [Code components](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/custom-controls-overview)
- [React controls and platform libraries](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/react-controls-platform-libraries)
- [Manifest schema reference](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/manifest-schema-reference/)
- [PCF API reference](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/reference/)
- [Use code components in Power Pages](https://learn.microsoft.com/en-us/power-pages/configure/component-framework)

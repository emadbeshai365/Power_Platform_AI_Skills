# Host and API capability matrix

## Contents

- How to use this matrix
- Host baseline
- Context API matrix
- Manifest capability matrix
- Compatibility decision record
- Official references

## How to use this matrix

Treat this file as a release gate, not a substitute for the current Microsoft API page. Availability can change independently for an API, method, manifest element, and host.

1. List the exact hosts: model-driven, canvas, and/or Power Pages.
2. List every `context.*` API and specialized manifest element used.
3. Check the current Microsoft page's **Available for** section.
4. Mark each dependency `required`, `optional with fallback`, or `excluded host`.
5. Test each promised host. Do not infer Canvas or Power Pages support from model-driven success.

## Host baseline

| Capability | Model-driven | Canvas | Power Pages |
| --- | --- | --- | --- |
| Standard field control | Yes | Yes | Supported field scenarios only |
| React virtual control | Yes | Yes | No |
| Dataset control | Yes | Supported with host differences | Do not promise; current Pages guidance is field-oriented |
| `property-set` | Yes for datasets | Verify current schema/host | No documented parity |
| Object outputs | Yes | Yes, with schema dependency | Verify current API and Pages scenario |
| Custom events | Preview | Preview | Do not promise |
| Local harness fidelity | Partial | Partial | No Pages emulator |

## Context API matrix

The table records safe routing guidance from current Microsoft documentation. Recheck the linked API reference before implementation.

| API family | Model-driven | Canvas | Power Pages | Engineering rule |
| --- | --- | --- | --- | --- |
| Parameters, mode, resources, client, user settings | Yes | Yes | Scenario-dependent | Null-check host-provided values and test the target surface. |
| Formatting | Yes | Yes | Scenario-dependent | Prefer platform formatting over handcrafted locale logic. |
| Navigation | Yes | Yes for documented methods | Limited | Check each method, not only the family page. |
| Web API | Yes | No documented parity | Do not promise | Use only after confirming availability and Dataverse privileges. |
| Utility | Yes | No | Explicitly unsupported | Provide an alternative or exclude the host. |
| Device APIs | Method-specific | Method-specific | Barcode, position, and file picking are unsupported | Declare feature usage only where supported. |
| Factory / PopupService | Yes | Yes where documented | Do not promise | Dispose popups and avoid using them as a cross-host abstraction. |
| Theming (`fluentDesignLanguage`) | Yes | Yes | No documented virtual-control parity | Use Fluent v9 tokens and a tested fallback. |
| Events | Preview | Preview | Do not promise | Require explicit preview acceptance and host tests. |
| Linking / linked tables | Yes | No documented parity | No | Keep linking logic in model-driven variants. |
| Dataset APIs | Yes | Supported subset/pattern differences | No documented parity | Test paging, selection, filtering, sorting, commands, and refresh in-host. |
| File/image APIs and provider types | Method/type-specific | Method/type-specific | Limited | Validate size limits, MIME types, cancellation, security, and object URL cleanup. |

Never use `Xrm`, `formContext`, private context members, parent-window DOM, or undocumented globals from a component.

## Manifest capability matrix

| Element/attribute | Model-driven | Canvas | Power Pages | Rule |
| --- | --- | --- | --- | --- |
| `property`, `type-group`, `resources` | Yes | Yes | Restricted supported field types | Validate each type against the host. |
| `data-set`, `property-set` | Yes | Supported patterns differ | Not supported as a general Pages contract | Do not promise dataset parity. |
| `feature-usage` | Yes | Check current element guidance | `uses-feature` must not be `required="true"` | Pages requires a degraded path. |
| `external-service-usage` | Yes | Yes | Check current Pages behavior | Declare every directly contacted domain and licensing impact. |
| `event` | Preview | Preview | Do not promise | Generate types, document maker wiring, and test both host handlers. |
| `property-dependencies` | No | Yes | No | Use for Canvas schema dependencies such as Object outputs. |
| `pfx-default-value` | No | Yes | No | Treat as Canvas-only maker behavior. |
| `platform-library` | React virtual controls | React virtual controls | No | Do not convert a standard control by editing XML only. |
| `platform-action` | Yes | No | No | `afterPageLoad` is model-driven only and tied to dependent libraries. |
| `html` resource | Host-restricted | Host-restricted | Verify | Prefer supported rendering architecture; do not assume arbitrary HTML resources load everywhere. |

## Compatibility decision record

Record this table in the implementation or handoff:

| Dependency | Used by | Host availability verified | Required/fallback | Evidence |
| --- | --- | --- | --- | --- |
| `context.webAPI` | Metadata load | Model-driven | Required; Canvas excluded | API link + host test |
| `context.fluentDesignLanguage` | Theme tokens | Model-driven, Canvas | Fallback theme | API link + light/dark tests |

If any required dependency is unavailable in a promised host, split the implementation, design a supported fallback, or remove that host from the contract.

## Official references

- [PCF API reference](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/reference/)
- [Manifest schema reference](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/manifest-schema-reference/)
- [Code components for canvas apps](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/component-framework-for-canvas-apps)
- [Use code components in Power Pages](https://learn.microsoft.com/en-us/power-pages/configure/component-framework)
- [Theming API](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/reference/theming)

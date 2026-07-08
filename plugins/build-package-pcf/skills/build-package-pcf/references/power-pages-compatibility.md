# Power Pages compatibility gate

## Contents

- Supported boundary
- Mandatory rejection checks
- Design and implementation gate
- Configuration and runtime verification
- Handoff checklist
- Official references

## Supported boundary

Power Pages supports selected PCF controls built for model-driven app fields and rendered in webpage forms. It does not provide general parity with model-driven or Canvas hosts.

Use a separate Power Pages compatibility decision even when the same control also targets model-driven apps.

## Mandatory rejection checks

Do not promise Power Pages support when any of these is required:

- React virtual controls or platform React/Fluent libraries;
- dataset controls or a multi-field bound-control contract;
- `Device.getBarcodeValue`, `Device.getCurrentPosition`, or `Device.pickFile`;
- the Utility API;
- a `uses-feature` entry that is required;
- unsupported manifest value elements or field data types;
- phone/tablet client behavior rather than the supported web-client option.

If one is present, create a supported standard field-control variant, design a fallback, or remove Power Pages from the supported-host list.

## Design and implementation gate

1. Use `StandardControl`; own and clean up the DOM lifecycle.
2. Bind only the supported form field scenario.
3. Keep the manifest contract minimal and avoid host-specific optional features.
4. Use asynchronous calls and account for portal authentication and Dataverse table permissions.
5. Avoid assuming model-driven navigation, dialog, utility, theming, or form APIs exist.
6. Scope CSS beneath the component root and test it against the site's theme and responsive layout.
7. Provide loading, unauthenticated/unauthorized, empty, error, and read-only behavior.
8. Treat external service calls as browser calls: declare domains, review CORS/CSP, licensing, privacy, and secret exposure.

## Configuration and runtime verification

Before testing:

- confirm the environment/site meets Microsoft's current version prerequisites;
- enable the code component feature using the supported administration path;
- add the component to the Dataverse form field;
- configure the field in the Power Pages form/basic-form experience;
- select the supported Web client option;
- verify table permissions and web roles for anonymous and authenticated scenarios.

Test in the deployed site, not only the PCF harness or model-driven form:

- anonymous and signed-in users as applicable;
- allowed and denied table operations;
- responsive widths and supported browsers;
- localization, right-to-left layout when required, and site theme interaction;
- CSP/CORS and external-service failure;
- refresh, navigation away, and component destruction;
- multiple instances and slow networks.

## Handoff checklist

Report:

- exact supported field types and site pages/forms;
- unsupported APIs/features intentionally excluded;
- environment/site prerequisite and feature-toggle status;
- table permissions and web roles required;
- browsers and authentication states tested;
- external domains, premium licensing effect, and privacy considerations;
- any behavior verified only in model-driven apps and still untested in Pages.

## Official references

- [Use code components in Power Pages](https://learn.microsoft.com/en-us/power-pages/configure/component-framework)
- [PCF overview](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/overview)
- [Best practices for code components](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/code-components-best-practices)

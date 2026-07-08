# CI, release validation, and source governance

## Contents

- Deterministic pipeline
- Release gates
- Versioning and artifact checks
- Preview and deprecation policy
- Microsoft-source refresh procedure
- Evidence retention
- Official references

## Deterministic pipeline

Use an ephemeral Windows or Linux agent with pinned, supported tool versions.

1. Check out the exact commit.
2. Record Node.js, npm, PAC CLI, `pcf-scripts`, .NET/MSBuild, and operating-system versions.
3. Restore with `npm ci`; fail when the committed lockfile is missing or changed.
4. Run the cross-platform semantic audit for the declared hosts.
5. Run lint, type checks, and unit tests.
6. Build every component with `--buildMode production`.
7. Synchronize component and solution versions according to repository policy.
8. Build the `.cdsproj` in Release with an explicit `SolutionPackageType`.
9. Verify artifacts were created during this run, open as ZIP files, contain solution metadata, and match intended managed state.
10. Publish immutable packages plus the evidence report. Do not deploy from an unverified workspace artifact.

Use Microsoft Power Platform Build Tools for Azure DevOps or Microsoft Power Platform GitHub Actions where they add supported environment operations. Keep component build/audit commands visible rather than hiding correctness gates in a single opaque task.

Copy and tailor the bundled starter matching the repository:

- `assets/ci/github-actions-pcf.yml`
- `assets/ci/azure-pipelines-pcf.yml`

Update component, solution, host, runtime-version, and auditor paths before use. Keep deployment in a separately authorized stage with environment approvals.

## Release gates

| Gate | Failure policy |
| --- | --- |
| Manifest/PAC schema build | Block |
| Semantic host compatibility | Block required incompatibilities; review warnings |
| Lint/type/unit tests | Block unless an approved exception is recorded |
| Production bundle | Block development-mode artifacts |
| Dependency vulnerabilities/licenses | Triage by exploitability and policy; never blind auto-fix |
| Accessibility/keyboard checks | Block critical user paths |
| Real-host smoke tests | Block promised host release when not tested |
| Solution version/type/integrity | Block |
| Solution checker | Run where applicable; do not claim it guarantees PCF runtime correctness or import success |

## Versioning and artifact checks

- Keep namespace and constructor stable after release.
- Advance the manifest control version for changed component code.
- Advance solution version according to update/upgrade strategy.
- In automated pipelines, derive both versions from one documented build-version source when feasible.
- Build all `pcfproj` references in a multi-component `cdsproj`; do not assume one component per solution.
- Resolve `ProjectReference` paths exactly, not by filename substring.
- Reject artifacts older than the pipeline build start.
- Inspect `solution.xml` inside each ZIP and verify `<Managed>` against the intended package type.
- Record SHA-256 hashes, sizes, absolute artifact paths, source commit, and tool versions.

## Preview and deprecation policy

Classify every non-baseline capability:

| Status | Use policy |
| --- | --- |
| GA | Use after normal host/API verification. |
| Preview/pre-release | Require explicit user/team acceptance, isolation, test coverage, and fallback/removal plan. |
| Deprecated | Do not add to new work; create migration plan for existing work. |
| Unsupported/undocumented | Do not use. |

Record the Microsoft page, last-reviewed date, target host, and fallback. Recheck preview features before every production release.

## Microsoft-source refresh procedure

The sample index is a maintained snapshot, not permanent truth.

1. Record the UTC review date and the exact `microsoft/PowerApps-Samples` commit used.
2. Compare `component-framework/` directories with the existing sample index.
3. For each new/changed sample, inspect its manifest, entry point, README, architecture, host, feature status, and warnings.
4. Update the sample-to-pattern mapping; do not paste entire sample implementations.
5. Recheck Microsoft Learn pages for overview, API reference, manifest schema, best practices, React platform libraries, canvas, Power Pages, and ALM.
6. Update GA/preview/deprecated labels and host matrix.
7. Run skill, plugin, link, and script validations.

Keep a compact source stamp in the sample index:

```text
Last verified: YYYY-MM-DD UTC
Sample repository commit: <full SHA>
Documentation baseline: Microsoft Learn pages linked by this skill
```

## Evidence retention

Publish or retain:

- semantic-audit JSON;
- test and coverage reports;
- production bundle and solution build logs;
- artifact hashes and package metadata;
- host smoke-test results;
- preview exceptions and security/license review;
- source commit and tool-version inventory.

Do not retain PAC credentials, access tokens, environment secrets, or user data in logs or artifacts.

## Official references

- [PCF application lifecycle management](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/code-components-alm)
- [Power Platform ALM basics](https://learn.microsoft.com/en-us/power-platform/alm/basics-alm)
- [Best practices for code components](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/code-components-best-practices)
- [Solution checker](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/use-powerapps-checker)
- [Platform action](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/manifest-schema-reference/platform-action)

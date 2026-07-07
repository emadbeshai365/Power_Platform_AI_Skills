# Power Platform AI Skills

Reusable Codex skills for Microsoft Power Platform development.

## Available skills

### `build-package-pcf`

Creates, modifies, validates, tests, and packages Microsoft Power Apps Component Framework (PCF) components. It supports field and dataset controls, standard HTML and React rendering, production builds, and managed or unmanaged Dataverse solution packages.

See [`skills/build-package-pcf/SKILL.md`](skills/build-package-pcf/SKILL.md).

## Install

Copy a skill folder into your Codex skills directory:

```powershell
Copy-Item -Recurse ./skills/build-package-pcf "$HOME/.codex/skills/build-package-pcf"
```

Then invoke it with `$build-package-pcf`.

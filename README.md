# Power Platform AI Skills

Reusable Claude and Codex skills for Microsoft Power Platform development.

## Available skills

### `build-package-pcf`

Creates, modifies, validates, tests, and packages Microsoft Power Apps Component Framework (PCF) components. It supports field and dataset controls, standard HTML and React rendering, production builds, and managed or unmanaged Dataverse solution packages.

See [`skills/build-package-pcf/SKILL.md`](skills/build-package-pcf/SKILL.md).

## Install in Claude

Add the repository as a marketplace, then install the PCF plugin:

```text
/plugin marketplace add emadbeshai365/Power_Platform_AI_Skills
/plugin install build-package-pcf@power-platform-ai-skills
```

Invoke the installed skill with:

```text
/build-package-pcf:build-package-pcf
```

Claude may also select the skill automatically when a request matches its description.

## Install in Codex

Copy a skill folder into your Codex skills directory:

```powershell
Copy-Item -Recurse ./skills/build-package-pcf "$HOME/.codex/skills/build-package-pcf"
```

Then invoke it with `$build-package-pcf`.

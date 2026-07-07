# Power Platform AI Skills

Reusable Claude and Codex skills for Microsoft Power Platform development.

## Available skills

### `build-package-pcf`

Designs, scaffolds, implements, reviews, troubleshoots, tests, optimizes, versions, and packages production-grade Microsoft Power Apps Component Framework (PCF) components. It includes architecture and host selection, manifest engineering, field and dataset patterns, React virtual controls, an indexed guide to Microsoft's official samples, accessibility/security/performance gates, deterministic project auditing, and Dataverse ALM.

See [`plugins/build-package-pcf/skills/build-package-pcf/SKILL.md`](plugins/build-package-pcf/skills/build-package-pcf/SKILL.md).

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

Add the GitHub repository as a plugin marketplace:

- Source: `https://github.com/emadbeshai365/Power_Platform_AI_Skills.git`
- Git ref: `main`
- Sparse paths: leave empty

Then install **Build & Package PCF** from the marketplace.

To install only the standalone skill instead, copy its folder into your Codex skills directory:

```powershell
Copy-Item -Recurse ./plugins/build-package-pcf/skills/build-package-pcf "$HOME/.codex/skills/build-package-pcf"
```

Then invoke it with `$build-package-pcf`.

#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const supportedHosts = new Set(["model-driven", "canvas", "power-pages"]);
const excludedDirectories = new Set(["node_modules", "out", "obj", "bin", ".git"]);

function usage() {
  console.log(`Usage: node inspect-pcf-project.mjs <project-directory|pcfproj> [options]

Options:
  --hosts <list>  Comma-separated: model-driven,canvas,power-pages
  --json          Emit machine-readable JSON
  --help          Show this help`);
}

function parseArgs(argv) {
  const result = { projectPath: "", hosts: [], json: false };
  for (let index = 0; index < argv.length; index += 1) {
    const value = argv[index];
    if (value === "--help" || value === "-h") return { help: true };
    if (value === "--json") {
      result.json = true;
      continue;
    }
    if (value === "--hosts") {
      const hostValue = argv[index + 1];
      if (!hostValue) throw new Error("--hosts requires a comma-separated value.");
      result.hosts = hostValue.split(",").map((host) => host.trim().toLowerCase()).filter(Boolean);
      index += 1;
      continue;
    }
    if (value.startsWith("--")) throw new Error(`Unknown option: ${value}`);
    if (result.projectPath) throw new Error("Pass exactly one project path.");
    result.projectPath = value;
  }
  if (!result.projectPath) throw new Error("A project directory or .pcfproj path is required.");
  const invalidHosts = result.hosts.filter((host) => !supportedHosts.has(host));
  if (invalidHosts.length) throw new Error(`Unsupported host(s): ${invalidHosts.join(", ")}.`);
  return result;
}

function walk(root, predicate, matches = []) {
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    if (entry.isDirectory() && excludedDirectories.has(entry.name)) continue;
    const fullPath = path.join(root, entry.name);
    if (entry.isDirectory()) walk(fullPath, predicate, matches);
    else if (predicate(entry.name, fullPath)) matches.push(fullPath);
  }
  return matches;
}

function resolveProject(inputPath) {
  const resolved = path.resolve(inputPath);
  if (!fs.existsSync(resolved)) throw new Error(`Project path does not exist: ${resolved}`);
  const stat = fs.statSync(resolved);
  if (stat.isFile()) {
    if (!resolved.toLowerCase().endsWith(".pcfproj")) throw new Error("Project file must end in .pcfproj.");
    return resolved;
  }
  const projects = fs.readdirSync(resolved)
    .filter((name) => name.toLowerCase().endsWith(".pcfproj"))
    .map((name) => path.join(resolved, name));
  if (projects.length !== 1) throw new Error(`Expected one .pcfproj directly in ${resolved}; found ${projects.length}.`);
  return projects[0];
}

function decodeXml(value = "") {
  return value
    .replaceAll("&quot;", '"')
    .replaceAll("&apos;", "'")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">")
    .replaceAll("&amp;", "&");
}

function attributes(source = "") {
  const result = {};
  const pattern = /([\w:-]+)\s*=\s*(?:"([^"]*)"|'([^']*)')/g;
  for (const match of source.matchAll(pattern)) result[match[1]] = decodeXml(match[2] ?? match[3] ?? "");
  return result;
}

function elements(xml, name) {
  const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const pattern = new RegExp(`<${escaped}\\b([^>]*?)(?:\\/\\s*>|>([\\s\\S]*?)<\\/${escaped}\\s*>)`, "gi");
  return [...xml.matchAll(pattern)].map((match) => ({ attrs: attributes(match[1]), body: match[2] ?? "", raw: match[0] }));
}

function findEntrySource(controlDirectory, resources, findings) {
  const code = resources.find((resource) => resource.name === "code");
  if (!code?.attrs.path) return "";
  const entryPath = path.resolve(controlDirectory, code.attrs.path);
  if (!fs.existsSync(entryPath)) {
    findings.push(issue("PCF103", "error", `Code resource does not exist: ${code.attrs.path}`));
    return "";
  }
  return fs.readFileSync(entryPath, "utf8");
}

function issue(code, severity, message, evidence = undefined) {
  return { code, severity, message, ...(evidence ? { evidence } : {}) };
}

function inspect(options) {
  const project = resolveProject(options.projectPath);
  const projectDirectory = path.dirname(project);
  const findings = [];
  const facts = { project, projectDirectory, hosts: options.hosts };

  const packagePath = path.join(projectDirectory, "package.json");
  if (!fs.existsSync(packagePath)) findings.push(issue("PCF001", "error", "package.json is missing beside the .pcfproj."));
  else {
    try {
      const packageJson = JSON.parse(fs.readFileSync(packagePath, "utf8"));
      facts.packageName = packageJson.name ?? null;
      facts.packageScripts = Object.keys(packageJson.scripts ?? {});
      if (!packageJson.scripts?.build) findings.push(issue("PCF002", "error", "package.json does not define a build script."));
      if (!packageJson.scripts?.lint) findings.push(issue("PCF003", "warning", "No lint script is defined."));
      if (!packageJson.scripts?.test) findings.push(issue("PCF004", "warning", "No test script is defined."));
      if (!fs.existsSync(path.join(projectDirectory, "package-lock.json"))) findings.push(issue("PCF005", "warning", "No package-lock.json; deterministic npm ci restore is unavailable."));
    } catch (error) {
      findings.push(issue("PCF006", "error", `package.json could not be parsed: ${error.message}`));
    }
  }

  const manifests = walk(projectDirectory, (name) => name === "ControlManifest.Input.xml");
  if (manifests.length !== 1) {
    findings.push(issue("PCF100", "error", `Expected one source ControlManifest.Input.xml; found ${manifests.length}.`));
    return finish(facts, findings);
  }

  const manifestPath = manifests[0];
  const controlDirectory = path.dirname(manifestPath);
  const xml = fs.readFileSync(manifestPath, "utf8");
  facts.manifest = manifestPath;
  if (!/<manifest\b/i.test(xml) || !/<control\b/i.test(xml)) findings.push(issue("PCF101", "error", "Manifest/control root element is missing."));

  const control = elements(xml, "control")[0];
  if (!control) return finish(facts, findings);
  const controlType = control.attrs["control-type"] || "standard";
  facts.componentId = `${control.attrs.namespace ?? ""}.${control.attrs.constructor ?? ""}`;
  facts.version = control.attrs.version ?? null;
  facts.controlType = controlType;
  if (!control.attrs.namespace || !control.attrs.constructor) findings.push(issue("PCF102", "error", "Control namespace and constructor are required."));
  if (!/^\d+\.\d+\.\d+(?:\.\d+)?$/.test(control.attrs.version ?? "")) findings.push(issue("PCF104", "warning", `Control version '${control.attrs.version ?? ""}' is not a conventional numeric version.`));
  if (!["standard", "virtual"].includes(controlType)) findings.push(issue("PCF105", "error", `Unsupported control-type '${controlType}'.`));

  const resourceContainer = elements(control.body, "resources")[0];
  const resourceNames = ["code", "css", "resx", "img", "html", "platform-library"];
  const resources = resourceContainer ? resourceNames.flatMap((name) => elements(resourceContainer.body, name).map((item) => ({ name, ...item }))) : [];
  if (!resourceContainer) findings.push(issue("PCF106", "error", "Manifest does not contain a resources element."));
  for (const resource of resources) {
    if (!resource.attrs.path) continue;
    const resourcePath = path.resolve(controlDirectory, resource.attrs.path);
    if (!fs.existsSync(resourcePath)) findings.push(issue("PCF107", "error", `Manifest resource does not exist: ${resource.attrs.path}`));
  }
  if (!resources.some((resource) => resource.name === "code")) findings.push(issue("PCF108", "error", "Manifest does not declare a code resource."));

  const libraries = resources.filter((resource) => resource.name === "platform-library").map((resource) => resource.attrs.name);
  if (controlType === "virtual" && !libraries.includes("React")) findings.push(issue("PCF109", "error", "Virtual control does not declare the React platform library."));
  if (controlType === "standard" && libraries.length) findings.push(issue("PCF110", "warning", "Standard control declares platform libraries; verify the architecture."));

  const entrySource = findEntrySource(controlDirectory, resources, findings);
  if (controlType === "virtual" && entrySource && !/ComponentFramework\.ReactControl/.test(entrySource)) findings.push(issue("PCF111", "warning", "Virtual entry point does not visibly implement ReactControl."));
  if (controlType === "standard" && entrySource && !/ComponentFramework\.StandardControl/.test(entrySource)) findings.push(issue("PCF112", "warning", "Standard entry point does not visibly implement StandardControl."));
  if (controlType === "virtual" && /ReactDOM\.render/.test(entrySource)) findings.push(issue("PCF113", "error", "Virtual control calls ReactDOM.render; return a ReactElement from updateView."));

  const properties = elements(control.body, "property");
  const datasets = elements(control.body, "data-set");
  const events = elements(control.body, "event");
  const features = elements(control.body, "uses-feature");
  const actions = elements(control.body, "platform-action");
  facts.architecture = `${controlType} ${datasets.length ? "dataset" : "field"}`;
  facts.propertyCount = properties.length;
  facts.datasetCount = datasets.length;
  facts.eventCount = events.length;

  const names = properties.map((property) => property.attrs.name).filter(Boolean);
  const duplicates = [...new Set(names.filter((name, index) => names.indexOf(name) !== index))];
  if (duplicates.length) findings.push(issue("PCF200", "error", `Duplicate property names: ${duplicates.join(", ")}.`));
  for (const property of properties) {
    if (!property.attrs.name || !property.attrs.usage || (!property.attrs["of-type"] && !property.attrs["of-type-group"])) findings.push(issue("PCF201", "error", "Every property needs name, usage, and type/type-group.", property.raw.slice(0, 240)));
  }

  const objectOutputs = properties.filter((property) => property.attrs["of-type"] === "Object" && property.attrs.usage === "output");
  if (objectOutputs.length && !/\bgetOutputSchema\s*\(/.test(entrySource)) findings.push(issue("PCF202", "error", "Object output exists but getOutputSchema was not found in the entry point."));
  if (objectOutputs.length && options.hosts.includes("canvas") && !/<property-dependencies\b/i.test(control.body)) findings.push(issue("PCF203", "error", "Canvas Object output requires property-dependencies/schema wiring."));
  if (events.length) findings.push(issue("PCF204", "warning", "Custom events are pre-release; record explicit preview acceptance and host tests."));
  if (/<pfx-default-value\b/i.test(control.body) && options.hosts.some((host) => host !== "canvas")) findings.push(issue("PCF205", "warning", "pfx-default-value is Canvas-specific but non-Canvas hosts were declared."));
  if (actions.length && options.hosts.some((host) => host !== "model-driven")) findings.push(issue("PCF206", "error", "platform-action is model-driven only."));

  if (options.hosts.includes("power-pages")) {
    if (controlType === "virtual") findings.push(issue("PCF300", "error", "React virtual controls are not supported for Power Pages."));
    if (datasets.length) findings.push(issue("PCF301", "error", "Do not promise general dataset controls for Power Pages."));
    const requiredFeatures = features.filter((feature) => feature.attrs.required === "true");
    if (requiredFeatures.length) findings.push(issue("PCF302", "error", "Power Pages requires used features to be optional, not required."));
    const unsupportedFeatures = features.filter((feature) => ["Device.getBarcodeValue", "Device.getCurrentPosition", "Device.pickFile", "Utility"].includes(feature.attrs.name));
    if (unsupportedFeatures.length) findings.push(issue("PCF303", "error", `Unsupported Power Pages feature(s): ${unsupportedFeatures.map((feature) => feature.attrs.name).join(", ")}.`));
    const boundProperties = properties.filter((property) => property.attrs.usage === "bound");
    if (boundProperties.length > 1) findings.push(issue("PCF304", "error", "Power Pages does not support controls bound to multiple fields."));
    if (events.length) findings.push(issue("PCF305", "error", "Do not promise custom-event support for Power Pages."));
  }

  if (!options.hosts.length) findings.push(issue("PCF400", "warning", "No --hosts value was provided; host compatibility checks are incomplete."));
  if (!fs.existsSync(path.join(controlDirectory, "generated", "ManifestTypes.d.ts"))) findings.push(issue("PCF401", "warning", "generated/ManifestTypes.d.ts is absent; restore/build before release validation."));

  return finish(facts, findings);
}

function finish(facts, findings) {
  const errors = findings.filter((finding) => finding.severity === "error");
  const warnings = findings.filter((finding) => finding.severity === "warning");
  return { valid: errors.length === 0, facts, summary: { errors: errors.length, warnings: warnings.length }, findings };
}

function printHuman(result) {
  console.log("PCF semantic audit");
  console.log(`Project: ${result.facts.project}`);
  if (result.facts.componentId) console.log(`Component: ${result.facts.componentId}`);
  if (result.facts.architecture) console.log(`Architecture: ${result.facts.architecture}`);
  console.log(`Hosts: ${result.facts.hosts?.join(", ") || "not declared"}`);
  for (const finding of result.findings) console.log(`${finding.severity.toUpperCase()} ${finding.code}: ${finding.message}`);
  console.log(`Result: ${result.valid ? "PASS" : "FAIL"} (${result.summary.errors} error(s), ${result.summary.warnings} warning(s))`);
}

try {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    usage();
    process.exit(0);
  }
  const result = inspect(options);
  if (options.json) console.log(JSON.stringify(result, null, 2));
  else printHuman(result);
  process.exit(result.valid ? 0 : 1);
} catch (error) {
  console.error(`ERROR PCF000: ${error.message}`);
  usage();
  process.exit(2);
}

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { fileURLToPath } from "node:url";

const currentDirectory = path.dirname(fileURLToPath(import.meta.url));
const auditor = path.resolve(currentDirectory, "..", "inspect-pcf-project.mjs");

function createProject({ virtual = false, dataset = false, feature = "" } = {}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "pcf-audit-"));
  const control = path.join(root, "SampleControl");
  fs.mkdirSync(path.join(control, "generated"), { recursive: true });
  fs.writeFileSync(path.join(root, "Sample.pcfproj"), "<Project><PropertyGroup><PcfBuildMode>production</PcfBuildMode></PropertyGroup></Project>");
  fs.writeFileSync(path.join(root, "package.json"), JSON.stringify({ name: "sample", scripts: { build: "pcf-scripts build", lint: "echo lint", test: "echo test", start: "pcf-scripts start" } }));
  fs.writeFileSync(path.join(root, "package-lock.json"), "{}");
  fs.writeFileSync(path.join(control, "generated", "ManifestTypes.d.ts"), "export interface IInputs {}\nexport interface IOutputs {}\n");
  fs.writeFileSync(path.join(control, "index.ts"), `export class Sample implements ComponentFramework.${virtual ? "ReactControl" : "StandardControl"}<IInputs, IOutputs> {}`);
  const binding = dataset
    ? '<data-set name="items" display-name-key="Items" />'
    : '<property name="value" display-name-key="Value" of-type="SingleLine.Text" usage="bound" required="true" />';
  const libraries = virtual ? '<platform-library name="React" version="16.14.0" />' : "";
  const featureXml = feature ? `<feature-usage><uses-feature name="${feature}" required="true" /></feature-usage>` : "";
  fs.writeFileSync(path.join(control, "ControlManifest.Input.xml"), `<?xml version="1.0"?>
<manifest><control namespace="Contoso" constructor="Sample" version="1.0.0" display-name-key="Sample" control-type="${virtual ? "virtual" : "standard"}">
${binding}<resources><code path="index.ts" order="1" />${libraries}</resources>${featureXml}
</control></manifest>`);
  return root;
}

function run(project, hosts) {
  const result = spawnSync(process.execPath, [auditor, project, "--hosts", hosts, "--json"], { encoding: "utf8" });
  return { ...result, report: JSON.parse(result.stdout) };
}

test("passes a valid standard field control", () => {
  const project = createProject();
  try {
    const result = run(project, "model-driven,canvas");
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.report.valid, true);
    assert.equal(result.report.facts.architecture, "standard field");
  } finally {
    fs.rmSync(project, { recursive: true, force: true });
  }
});

test("rejects Power Pages-incompatible architecture and features", () => {
  const project = createProject({ virtual: true, dataset: true, feature: "Device.pickFile" });
  try {
    const result = run(project, "power-pages");
    assert.equal(result.status, 1);
    const codes = result.report.findings.map((finding) => finding.code);
    assert.ok(codes.includes("PCF300"));
    assert.ok(codes.includes("PCF301"));
    assert.ok(codes.includes("PCF302"));
    assert.ok(codes.includes("PCF303"));
  } finally {
    fs.rmSync(project, { recursive: true, force: true });
  }
});

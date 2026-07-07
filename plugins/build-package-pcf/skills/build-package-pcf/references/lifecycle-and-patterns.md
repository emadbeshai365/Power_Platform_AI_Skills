# Lifecycle and implementation patterns

## Contents

- Lifecycle contract
- State synchronization
- StandardControl pattern
- ReactControl pattern
- Dataset pattern
- Async and Web API pattern
- Resize, state, and cleanup
- Anti-patterns

## Lifecycle contract

The platform owns the lifecycle:

```text
construct -> init -> updateView ... -> notifyOutputChanged -> getOutputs
                                     -> updateView ... -> destroy
```

### `init`

Use once for:

- storing callbacks and stable references;
- building one-time DOM structure for standard controls;
- registering stable listeners;
- requesting resize tracking when the design needs dimensions;
- starting guarded one-time metadata/configuration loads;
- restoring intentional session state.

Do not assume dataset values are ready. A React virtual control does not receive a container.

### `updateView`

Assume it can run frequently because a parameter, dataset, size, visibility, offline state, or framework property changed.

- Treat raw properties as temporarily null.
- Keep rendering deterministic from current host state plus explicit local state.
- Use `context.updatedProperties` as an optimization hint, not as the only correctness mechanism.
- Do not launch an unguarded request on every call.
- Do not call `notifyOutputChanged` merely because `updateView` ran.

### `notifyOutputChanged` and `getOutputs`

Call the callback when committed output state changes. The framework then asks for outputs synchronously.

- Separate draft UI state from committed output state.
- Debounce or commit on blur when keystroke-level updates would create excessive host events.
- Return only values declared as bound/output in the manifest.
- Return `undefined` only when clearing the output is intentional and supported by the contract.

### `destroy`

Clean up everything the component owns:

- DOM listeners using the same function references;
- timers, intervals, observers, subscriptions, and sockets;
- abortable requests and disposed flags;
- third-party editor/chart/map instances;
- object URLs and other browser resources.

## State synchronization

Avoid the classic feedback loop:

1. User edits local value.
2. Component calls `notifyOutputChanged`.
3. Host requests `getOutputs`.
4. Host later calls `updateView` with the committed value.

Track at least:

```typescript
private hostValue: string | null = null;
private draftValue = "";
private committedValue: string | undefined;
private editing = false;
```

On `updateView`, update draft state from the host only when the incoming host value changed and doing so will not overwrite an active draft. Define commit timing explicitly.

## StandardControl pattern

```typescript
export class StatusControl
  implements ComponentFramework.StandardControl<IInputs, IOutputs> {
  private notifyOutputChanged!: () => void;
  private input!: HTMLInputElement;
  private value: string | undefined;

  private readonly onChange = (event: Event): void => {
    const next = (event.currentTarget as HTMLInputElement).value;
    if (next !== this.value) {
      this.value = next;
      this.notifyOutputChanged();
    }
  };

  public init(
    context: ComponentFramework.Context<IInputs>,
    notifyOutputChanged: () => void,
    state: ComponentFramework.Dictionary,
    container: HTMLDivElement
  ): void {
    this.notifyOutputChanged = notifyOutputChanged;
    this.input = document.createElement("input");
    this.input.addEventListener("change", this.onChange);
    container.appendChild(this.input);
  }

  public updateView(context: ComponentFramework.Context<IInputs>): void {
    const hostValue = context.parameters.value.raw ?? "";
    if (this.input.value !== hostValue) this.input.value = hostValue;
    this.input.disabled = context.mode.isControlDisabled;
    this.input.setAttribute("aria-label", context.mode.label || "Status");
  }

  public getOutputs(): IOutputs {
    return { value: this.value };
  }

  public destroy(): void {
    this.input.removeEventListener("change", this.onChange);
  }
}
```

Do not copy this mechanically: align null/output semantics and event timing with the actual manifest.

## ReactControl pattern

Keep the PCF wrapper responsible for the platform boundary and a React component responsible for presentation.

```typescript
export class StatusControl
  implements ComponentFramework.ReactControl<IInputs, IOutputs> {
  private notifyOutputChanged!: () => void;
  private value: string | undefined;

  public init(
    context: ComponentFramework.Context<IInputs>,
    notifyOutputChanged: () => void,
    state: ComponentFramework.Dictionary
  ): void {
    this.notifyOutputChanged = notifyOutputChanged;
  }

  private readonly commit = (value: string): void => {
    if (value !== this.value) {
      this.value = value;
      this.notifyOutputChanged();
    }
  };

  public updateView(
    context: ComponentFramework.Context<IInputs>
  ): React.ReactElement {
    return React.createElement(StatusPicker, {
      value: context.parameters.value.raw ?? "",
      disabled: context.mode.isControlDisabled,
      onCommit: this.commit,
    });
  }

  public getOutputs(): IOutputs {
    return { value: this.value };
  }

  public destroy(): void {}
}
```

Rules:

- Do not call `ReactDOM.render` in a virtual control.
- Do not mutate props.
- Use stable callbacks rather than creating avoidable closures in hot render paths.
- Keep network/cache state outside purely presentational children or in a deliberate hook/service.
- Use platform Fluent providers/theming patterns supported by the current template and target hosts.

## Dataset pattern

Model dataset rendering as states:

```text
loading -> error | empty | ready
ready + paging/sorting/filtering/selection transitions
```

Read data deliberately:

```typescript
const dataSet = context.parameters.dataSet;

if (dataSet.loading) return renderLoading();
if (dataSet.error) return renderError(dataSet.errorMessage);
if (dataSet.sortedRecordIds.length === 0) return renderEmpty();

const rows = dataSet.sortedRecordIds.map((id) => {
  const record = dataSet.records[id];
  return {
    id,
    name: record.getFormattedValue("name"),
    reference: record.getNamedReference(),
  };
});
```

Dataset engineering rules:

- Use `sortedRecordIds` for host-defined ordering.
- Use formatted values for display and raw values for logic.
- Use visible column metadata rather than hard-coded labels in generic grids.
- Preserve selection across renders by record ID where the host contract allows it.
- Do not call `refresh()` after every render or page operation.
- Prevent overlapping `loadNextPage()` calls.
- Decide whether paging replaces or appends records based on the target-host API behavior.
- Test view changes, missing columns, secured columns, empty views, slow loads, and paging boundaries in the target host.

## Async and Web API pattern

Use an explicit request generation or abort mechanism:

```typescript
private requestGeneration = 0;
private disposed = false;

private async load(entityId: string): Promise<void> {
  const generation = ++this.requestGeneration;
  try {
    const result = await this.context.webAPI.retrieveRecord(
      "account",
      entityId,
      "?$select=name,accountnumber"
    );
    if (this.disposed || generation !== this.requestGeneration) return;
    this.remoteState = { kind: "ready", result };
  } catch (error) {
    if (this.disposed || generation !== this.requestGeneration) return;
    this.remoteState = { kind: "error", error: normalizeError(error) };
  }
}

public destroy(): void {
  this.disposed = true;
  this.requestGeneration++;
}
```

Use `$select`, `$filter`, `$orderby`, `$top`, paging links, and encoding carefully. Do not concatenate untrusted OData fragments. Handle missing privileges and service-protection responses as user-facing states, not console-only errors.

## Resize, state, and cleanup

- Call `trackContainerResize(true)` only if layout actually depends on allocated dimensions.
- Treat `allocatedWidth`/`allocatedHeight` values as host inputs and support constrained layouts.
- Use `setControlState` for intentional same-session UI state, not as durable storage.
- Avoid global mutable singletons because multiple control instances can coexist.
- Namespace CSS and DOM IDs per component instance.

## Anti-patterns

- Replacing `container.innerHTML` on every `updateView` for a complex control.
- Calling `notifyOutputChanged` inside `updateView` without an actual user/output transition.
- Recreating handlers and then attempting cleanup with different function instances.
- Performing Web API calls on every render.
- Reading `window.Xrm`, form DOM, or internal context properties.
- Editing generated TypeScript declarations.
- Treating the harness as proof of host compatibility.
- Bundling React into a virtual control.
- Storing secrets or sensitive data in browser storage.

## Official references

- [StandardControl](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/reference/control)
- [ReactControl](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/reference/react-control)
- [React controls and platform libraries](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/react-controls-platform-libraries)
- [DataSet](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/reference/dataset)
- [WebAPI](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/reference/webapi)
- [Best practices](https://learn.microsoft.com/en-us/power-apps/developer/component-framework/code-components-best-practices)

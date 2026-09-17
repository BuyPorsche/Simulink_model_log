# Simulink Model Model log — Design Spec

**Date:** 2026-07-22  
**Status:** Approved for implementation planning  
**Approach:** Snapshot-diff on save (Approach 1)

## 1. Goal

Provide a small MATLAB/Simulink toolbox that, when manually enabled for a model, automatically appends a human-readable Markdown Model log beside the `.slx` on every save, describing **structural** and **parameter** changes since the previous save.

## 2. Requirements

| ID | Requirement |
|----|-------------|
| R1 | Trigger on model save (after successful save) |
| R2 | Record block add/remove, line add/remove, and whitelist parameter changes |
| R3 | Write a sidecar `ModelName_model_log.md` next to the `.slx` |
| R4 | Append a dated section per save that has real changes; keep full history |
| R5 | Enable/disable by running MATLAB functions (or a starter `.m`); not global by default |
| R6 | Never block model save if logging fails |
| R7 | Ignore layout-only / UI noise (e.g. `Position`) so drag-only saves produce no entry |

### Out of scope (v1)

- Full parameter dump for every block type
- Model configuration set / solver / data dictionary deep diffs
- Referenced model recursive logging (only the model being saved)
- JSON dual output, HTML reports, Git hooks
- Automatic enable for all models on the machine

## 3. Architecture

Four modules in a MATLAB package (recommended layout: `+model_log/`):

| Module | Responsibility |
|--------|----------------|
| Enable / disable | Install or restore save callbacks; create or clear baseline state |
| Snapshot | Walk the model; capture blocks, whitelisted params, lines |
| Diff | Compare current snapshot to previous; emit typed change records |
| Writer | Append Markdown sections to the sidecar Log |

### Sidecar files (beside `MyModel.slx`)

```
MyModel.slx
MyModel_model_log.md              # human-readable append-only history
.MyModel_model_log_.mat      # last snapshot + callback metadata (gitignore recommended)
```

### Save-time data flow

```
User saves model
  → PreSaveFcn: record save context (model name, timestamp start)
  → Simulink writes .slx
  → PostSaveFcn:
       capture current snapshot
       diff vs state.snapshot
       if non-empty: append Markdown section
       replace state.snapshot with current
```

First `enable` only creates a baseline snapshot and installs callbacks; it does **not** append a change section. Logging starts from the next save that has a non-empty diff.

## 4. Public API

```matlab
enable(model)    % model: name, handle, or path; default bdroot
disable(model)   % optional name-value: KeepState (logical, default true)
tf = isEnabled(model)
```

Optional convenience script: `start_model_log.m` → `enable(bdroot)`.

### `enable` steps

1. Resolve and load the model if needed (`load_system`).
2. Capture baseline snapshot; write `.ModelName_model_log_.mat`.
3. Read existing `PreSaveFcn` / `PostSaveFcn`; store originals in state.
4. Install wrapped callbacks that chain: original (if any), then tool logic.
5. Persist enable timestamp and tool version in state.

### `disable` steps

1. Restore original `PreSaveFcn` / `PostSaveFcn` from state.
2. Leave `*_model_log.md` intact.
3. Delete or keep state file per `KeepState`.

## 5. Callbacks

| Callback | Role |
|----------|------|
| `PreSaveFcn` | Lightweight context stamp only |
| `PostSaveFcn` | Snapshot → diff → append Markdown → update state |

### Skip / special cases

- Empty diff (e.g. layout-only) → do not append.
- Missing or corrupt state → rebuild baseline; append a warning section to the Log; do not fail save.
- Read-only directory / write failure → `warning`, skip log write, do not fail save.
- Ambiguous same-named models → use the file path of the active `bdroot` being saved; write beside that `.slx`.

All tool code in callbacks runs inside `try/catch` so logging never aborts save.

## 6. Snapshot contents

Per non-annotation block:

| Category | Fields |
|----------|--------|
| Identity | Full path, `BlockType`, `MaskType` (if any), `Name` |
| Structure | Parent system path; presence for add/remove |
| Lines | Source port → destination port (`SrcBlock`/`SrcPort` → `DstBlock`/`DstPort`) |
| Parameters | Whitelisted `get_param` values, normalized to comparable strings |

### Explicitly ignored (v1)

`Position`, font/UI properties, transient handles, and other noisy graphics fields.

### Parameter whitelist (v1)

Layered policy, configurable via `param_whitelist.json` (or equivalent `.m` table) without changing core code:

1. **Common:** `SampleTime`, `OutDataTypeStr`, stable port dimension strings when readable  
2. **Common blocks:** e.g. Gain→`Gain`, Constant→`Value`, Inport/Outport→`Port`/`DataType`/`Unit`, core coeffs for Integrator / TransferFcn / PID-style blocks, small SubSystem flags such as `TreatAsAtomicUnit`  
3. **Extension:** user edits whitelist file to add block types / param names  

Blocks not in the whitelist still participate in **add/remove** and **line** diffs; only parameter diffs are limited to the whitelist.

### Snapshot logical schema

```text
Snapshot
  modelName, modelPath, capturedAt, toolVersion
  blocks: map path → BlockInfo
  lines:  list of {src, dst}
```

Serialized in `.ModelName_model_log_.mat` together with callback metadata.

### Diff record types

- `BlockAdded` / `BlockRemoved`
- `BlockTypeChanged` (same path, type change; rare)
- `ParamChanged` (path, paramName, oldValue, newValue)
- `LineAdded` / `LineRemoved`

## 7. Markdown format

- Path: `<modelDir>/<ModelName>_model_log.md`
- Encoding: UTF-8
- Create file with a short header on first write (tool name, model name, purpose)
- Append one section per save with real changes; omit empty subsections

### Section template (v1 language: Chinese)

```markdown
## 2026-07-22 11:34:05 | 用户: ELLX1JB | 模型: MyModel

### 模块新增
- `Controller/PID1` (BlockType: SubSystem)

### 模块删除
- `Plant/OldGain` (BlockType: Gain)

### 参数变更
| 模块 | 参数 | 旧值 | 新值 |
|------|------|------|------|
| `Controller/Gain1` | Gain | `1` | `2.5` |

### 连线变更
- 新增: `In1/1` → `Gain1/1`
- 删除: `Gain1/1` → `Out1/1`

---
```

State-reset warning example:

```markdown
## 2026-07-22 12:00:00 | 用户: ELLX1JB | 模型: MyModel

⚠ 日志状态文件缺失或损坏，已重建基线。本次保存未产生差异记录。

---
```

## 8. Repository layout (planned)

```text
Model_change_log/
  +model_log/
    enable.m
    disable.m
    isEnabled.m
    captureSnapshot.m
    diffSnapshots.m
    appendLog.m
    installCallbacks.m
    ...
  config/
    param_whitelist.json
  start_model_log.m
  .gitignore                 # ignore *_model_log_.mat (optional: keep md)
  docs/superpowers/specs/
    2026-07-22-simulink-model-Log-design.md
  examples/                  # small demo model + expected log snippets (later)
  tests/                     # MATLAB unit / smoke tests (later)
```

Exact file split may vary during implementation as long as public API and sidecar contracts stay stable.

## 9. Test plan (v1 acceptance)

1. `enable` → change a Gain → save → Markdown contains parameter row with old/new.  
2. Add/remove blocks and rewire → corresponding subsections appear.  
3. Move blocks only (layout) → no new section.  
4. `disable` → further saves do not append; original callbacks restored.  
5. Delete state file → next save warns, rebuilds baseline, save succeeds.  
6. Model with pre-existing `PostSaveFcn` → enable chains both; disable restores original string.

## 10. Decisions log

| Topic | Decision |
|-------|----------|
| Primary scenario | Auto log on each save |
| Detail level | Structure + whitelisted parameters (level B) |
| Log location | Sidecar beside `.slx` |
| History policy | Append-only full history |
| Activation | Manual via MATLAB function / starter script |
| Format | Markdown only |
| Implementation approach | Snapshot diff (not raw SLX XML diff, not visdiff-first) |

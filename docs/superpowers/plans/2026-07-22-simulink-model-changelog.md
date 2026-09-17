# Simulink Model Model log Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a MATLAB package that, after manual enable, appends structure+parameter change sections to `ModelName_model_log.md` beside a `.slx` on every save.

**Architecture:** Snapshot-diff on `PostSaveFcn`. Enable installs chained callbacks and a baseline `.ModelName_model_log_.mat`. Diff is pure MATLAB (unit-testable); capture walks the live model via `find_system` / `get_param` / line handles.

**Tech Stack:** MATLAB R2021b+ (target), Simulink, `matlab.unittest`, optional MATLAB MCP `run_matlab_test_file` for verification.

**Spec:** `docs/superpowers/specs/2026-07-22-simulink-model-Log-design.md`

## Global Constraints

- Trigger only after successful save (`PostSaveFcn`); never block save (R1, R6).
- Record blocks add/remove, lines add/remove, whitelist params only (R2, R7).
- Sidecar Markdown beside `.slx`, append-only Chinese section headers (R3, R4).
- Manual enable via `model_log.enable` / `start_model_log.m` (R5).
- Ignore layout/UI noise (`Position`, fonts, etc.) (R7).
- v1 does not recurse into model references, config sets, or data dictionaries.
- Public functions live in package `+model_log`; callbacks must call package-qualified names.
- State file name: `.<ModelName>_model_log_.mat`; log file: `<ModelName>_model_log.md`.
- Git commits only when the user explicitly asks (do not auto-commit during implementation unless requested).

---

## File Structure

| Path | Responsibility |
|------|----------------|
| `+model_log/enable.m` | Public: resolve model, baseline snapshot, install callbacks |
| `+model_log/disable.m` | Public: restore callbacks; optional state delete |
| `+model_log/isEnabled.m` | Public: query enable flag in state |
| `+model_log/resolveModel.m` | Name/handle/path → struct with `name`, `path`, `handle` |
| `+model_log/statePaths.m` | Compute Log.md and state.mat paths beside `.slx` |
| `+model_log/loadState.m` / `saveState.m` | Read/write state MAT file |
| `+model_log/captureSnapshot.m` | Live model → snapshot struct |
| `+model_log/loadWhitelist.m` | Load `config/param_whitelist.json` |
| `+model_log/diffSnapshots.m` | Pure diff → change records struct |
| `+model_log/formatLogSection.m` | Changes + meta → Markdown string |
| `+model_log/appendLog.m` | Ensure header + append section to `.md` |
| `+model_log/installCallbacks.m` | Chain-wrap Pre/PostSaveFcn |
| `+model_log/onPreSave.m` | Lightweight pre-save stamp in state |
| `+model_log/onPostSave.m` | Snapshot → diff → append → update state (try/catch) |
| `config/param_whitelist.json` | BlockType → param name list + common list |
| `start_model_log.m` | Convenience: enable on `bdroot` |
| `setupPath.m` | `addpath` repo root so package resolves |
| `.gitignore` | Ignore `.*_model_log_.mat`, `*.asv`, `slprj/`, etc. |
| `tests/tDiffSnapshots.m` | Unit tests for pure diff |
| `tests/tformatLogSection.m` | Unit tests for Markdown formatting |
| `tests/tStatePaths.m` | Unit tests for path helpers |
| `tests/tEnableDisableSmoke.m` | Simulink smoke: enable → edit → save → assert md |
| `examples/demo_model_log.m` | Build tiny demo model and walk through enable/save |

### Shared data contracts

```matlab
% Snapshot
s.modelName     % char
s.modelPath     % char full path to .slx
s.capturedAt    % datetime or char ISO
s.toolVersion   % char e.g. '0.1.0'
s.blocks        % containers.Map: path(char) -> BlockInfo struct
s.lines         % Nx1 struct array: .src (char), .dst (char)
% BlockInfo: .path, .blockType, .maskType, .name, .params (struct of name->char)

% Diff / changes
c.blockAdded    % cellstr of paths (or struct with path, blockType)
c.blockRemoved  % cellstr / struct
c.blockTypeChanged % struct array .path .oldType .newType
c.paramChanged  % struct array .path .param .oldValue .newValue
c.lineAdded     % struct array .src .dst
c.lineRemoved   % struct array .src .dst

% State MAT variable `state`
state.enabled           % logical
state.toolVersion       % char
state.enabledAt         % char
state.originalPreSave   % char
state.originalPostSave  % char
state.snapshot          % Snapshot
state.lastPreSaveAt     % char (optional)
```

Line endpoint keys are canonical strings: `'BlockPath/PortNumber'` (e.g. `'Controller/Gain1/1'`).

---

### Task 1: Repo scaffold and path helpers

**Files:**
- Create: `.gitignore`
- Create: `setupPath.m`
- Create: `+model_log/statePaths.m`
- Create: `+model_log/resolveModel.m` (stub returning paths only when given a file path; full Simulink resolve in Task 5)
- Create: `tests/tStatePaths.m`

**Interfaces:**
- Consumes: none
- Produces:
  - `setupPath()` — adds repo root to MATLAB path
  - `[logPath, statePath] = model_log.statePaths(modelPath)` where `modelPath` is full path to `.slx` / `.mdl`
  - For `D:\work\MyModel.slx` → log `D:\work\MyModel_model_log.md`, state `D:\work\.MyModel_model_log_.mat`

- [ ] **Step 1: Write failing test `tests/tStatePaths.m`**

```matlab
classdef tStatePaths < matlab.unittest.TestCase
    methods (Test)
        function derivesSidecarNames(testCase)
            setupPath();
            slx = fullfile('C:', 'models', 'Plant.slx');
            [logPath, statePath] = model_log.statePaths(slx);
            testCase.verifyEqual(logPath, fullfile('C:', 'models', 'Plant_model_log.md'));
            testCase.verifyEqual(statePath, fullfile('C:', 'models', '.Plant_model_log_.mat'));
        end
    end
end
```

- [ ] **Step 2: Run test — expect fail (package/function missing)**

Run (MATLAB):
```matlab
cd('D:\98_Github\Model_change_log');
runtests('tests/tStatePaths.m')
```
Expected: FAIL — `model_log.statePaths` undefined or `setupPath` missing.

- [ ] **Step 3: Implement scaffold**

`.gitignore`:
```
.*_model_log_.mat
*.asv
slprj/
*.slxc
*.autosave
```

`setupPath.m`:
```matlab
function setupPath()
    root = fileparts(mfilename('fullpath'));
    addpath(root);
end
```

`+model_log/statePaths.m`:
```matlab
function [logPath, statePath] = statePaths(modelPath)
    [folder, name, ~] = fileparts(modelPath);
    logPath = fullfile(folder, [name '_model_log.md']);
    statePath = fullfile(folder, ['.' name '_model_log_.mat']);
end
```

- [ ] **Step 4: Re-run `tStatePaths` — expect PASS**

- [ ] **Step 5: Commit only if user asked** — otherwise stop and report Task 1 done

---

### Task 2: Pure diff engine (TDD)

**Files:**
- Create: `+model_log/diffSnapshots.m`
- Create: `+model_log/isEmptyChanges.m`
- Create: `tests/tDiffSnapshots.m`

**Interfaces:**
- Consumes: Snapshot contract above
- Produces:
  - `changes = model_log.diffSnapshots(oldSnap, newSnap)`
  - `tf = model_log.isEmptyChanges(changes)` — true iff all change arrays empty

- [ ] **Step 1: Write failing tests**

```matlab
classdef tDiffSnapshots < matlab.unittest.TestCase
    methods (Test)
        function detectsBlockAddRemove(testCase)
            setupPath();
            oldS = localSnap();
            oldS.blocks('A/G1') = localBlock('A/G1', 'Gain');
            newS = localSnap();
            newS.blocks('A/G2') = localBlock('A/G2', 'Gain');
            c = model_log.diffSnapshots(oldS, newS);
            testCase.verifyEqual(c.blockRemoved{1}.path, 'A/G1');
            testCase.verifyEqual(c.blockAdded{1}.path, 'A/G2');
            testCase.verifyFalse(model_log.isEmptyChanges(c));
        end

        function detectsParamChange(testCase)
            setupPath();
            oldS = localSnap();
            b = localBlock('A/G1', 'Gain'); b.params.Gain = '1';
            oldS.blocks('A/G1') = b;
            newS = localSnap();
            b2 = localBlock('A/G1', 'Gain'); b2.params.Gain = '2';
            newS.blocks('A/G1') = b2;
            c = model_log.diffSnapshots(oldS, newS);
            testCase.verifyEqual(c.paramChanged(1).param, 'Gain');
            testCase.verifyEqual(c.paramChanged(1).oldValue, '1');
            testCase.verifyEqual(c.paramChanged(1).newValue, '2');
        end

        function detectsLineChanges(testCase)
            setupPath();
            oldS = localSnap();
            oldS.lines = struct('src', {'In1/1'}, 'dst', {'G1/1'});
            newS = localSnap();
            newS.lines = struct('src', {'In1/1'}, 'dst', {'G2/1'});
            c = model_log.diffSnapshots(oldS, newS);
            testCase.verifyEqual(c.lineRemoved(1).dst, 'G1/1');
            testCase.verifyEqual(c.lineAdded(1).dst, 'G2/1');
        end

        function emptyWhenIdentical(testCase)
            setupPath();
            s = localSnap();
            s.blocks('A/G1') = localBlock('A/G1', 'Gain');
            c = model_log.diffSnapshots(s, s);
            testCase.verifyTrue(model_log.isEmptyChanges(c));
        end
    end
end

function s = localSnap()
    s.modelName = 'M'; s.modelPath = ''; s.capturedAt = ''; s.toolVersion = '0.1.0';
    s.blocks = containers.Map('KeyType','char','ValueType','any');
    s.lines = struct('src', {}, 'dst', {});
end

function b = localBlock(path, typ)
    b.path = path; b.blockType = typ; b.maskType = ''; b.name = '';
    b.params = struct();
end
```

Put helpers in the test file as local functions (MATLAB R2016b+ classdef file local functions) or a `tests/private` folder — prefer local functions at bottom of `tDiffSnapshots.m` if classdef allows; otherwise create `tests/fixtures/makeEmptySnapshot.m`.

- [ ] **Step 2: Run tests — expect FAIL**

- [ ] **Step 3: Implement `diffSnapshots` and `isEmptyChanges`**

Logic:
1. Keys only in new → `blockAdded` (include `.blockType` from new)
2. Keys only in old → `blockRemoved`
3. Keys in both: if `blockType` differs → `blockTypeChanged`; else for each field in union of `params`, if char values differ → `paramChanged`
4. Lines: canonicalize as `src||dst` set membership for add/remove
5. Initialize all change fields to empty so `isEmptyChanges` is reliable

- [ ] **Step 4: Run tests — expect PASS**

- [ ] **Step 5: Commit only if user asked**

---

### Task 3: Markdown formatter and append writer

**Files:**
- Create: `+model_log/formatLogSection.m`
- Create: `+model_log/appendLog.m`
- Create: `tests/tformatLogSection.m`

**Interfaces:**
- Consumes: `changes` from Task 2
- Produces:
  - `md = model_log.formatLogSection(meta, changes)`  
    `meta` fields: `.timestamp` (char), `.user` (char), `.modelName` (char)
  - `model_log.appendLog(logPath, meta, changes)` — if `isEmptyChanges`, no-op; else ensure UTF-8 file header once, then append section

Header (first create only):
```markdown
# Simulink 模型日志: <ModelName>

由 model_log 自动生成。每次保存若有结构/参数变更则追加一节。

```

Section must use Chinese headings exactly:
`### 模块新增` / `### 模块删除` / `### 参数变更` / `### 连线变更`  
and table columns `模块 | 参数 | 旧值 | 新值`.

- [ ] **Step 1: Write failing formatter tests**

```matlab
classdef tformatLogSection < matlab.unittest.TestCase
    methods (Test)
        function rendersParamTable(testCase)
            setupPath();
            meta.timestamp = '2026-07-22 11:34:05';
            meta.user = 'ELLX1JB';
            meta.modelName = 'MyModel';
            c = emptyChanges();
            c.paramChanged = struct('path', {'Controller/Gain1'}, ...
                'param', {'Gain'}, 'oldValue', {'1'}, 'newValue', {'2.5'});
            md = model_log.formatLogSection(meta, c);
            testCase.verifyTrue(contains(md, '## 2026-07-22 11:34:05 | 用户: ELLX1JB | 模型: MyModel'));
            testCase.verifyTrue(contains(md, '### 参数变更'));
            testCase.verifyTrue(contains(md, '`Controller/Gain1`'));
            testCase.verifyTrue(contains(md, '2.5'));
            testCase.verifyFalse(contains(md, '### 模块新增'));
        end

        function appendCreatesFileAndSkipsEmpty(testCase)
            setupPath();
            tmp = tempname; mkdir(tmp);
            logPath = fullfile(tmp, 'X_model_log.md');
            meta.timestamp = '2026-07-22 12:00:00'; meta.user = 'u'; meta.modelName = 'X';
            model_log.appendLog(logPath, meta, emptyChanges());
            testCase.verifyFalse(isfile(logPath));
            c = emptyChanges();
            c.blockAdded = {struct('path','A/B','blockType','Gain')};
            model_log.appendLog(logPath, meta, c);
            testCase.verifyTrue(isfile(logPath));
            txt = fileread(logPath);
            testCase.verifyTrue(contains(txt, '# Simulink 模型日志: X'));
            testCase.verifyTrue(contains(txt, '### 模块新增'));
        end
    end
end

function c = emptyChanges()
    c.blockAdded = {};
    c.blockRemoved = {};
    c.blockTypeChanged = struct('path', {}, 'oldType', {}, 'newType', {});
    c.paramChanged = struct('path', {}, 'param', {}, 'oldValue', {}, 'newValue', {});
    c.lineAdded = struct('src', {}, 'dst', {});
    c.lineRemoved = struct('src', {}, 'dst', {});
end
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement formatter + append**

Use `fopen` with `'a'` / `'w'` and `fwrite` UTF-8 (or `MATLAB` `writelines` if available). On Windows prefer explicit UTF-8 encoding when writing.

- [ ] **Step 4: Run — expect PASS**

- [ ] **Step 5: Commit only if user asked**

---

### Task 4: Whitelist config + snapshot capture

**Files:**
- Create: `config/param_whitelist.json`
- Create: `+model_log/loadWhitelist.m`
- Create: `+model_log/captureSnapshot.m`
- Create: `+model_log/toolVersion.m` → returns `'0.1.0'`
- Create: `tests/tLoadWhitelist.m`

**Interfaces:**
- Consumes: live Simulink model (for capture); JSON for whitelist
- Produces:
  - `wl = model_log.loadWhitelist()` — struct with `.common` (cellstr) and `.byBlockType` (struct or map)
  - `snap = model_log.captureSnapshot(modelName)` — filled Snapshot; does not read/write state

`config/param_whitelist.json` (v1 minimum):
```json
{
  "common": ["SampleTime", "OutDataTypeStr"],
  "byBlockType": {
    "Gain": ["Gain"],
    "Constant": ["Value"],
    "Inport": ["Port", "OutDataTypeStr", "Unit"],
    "Outport": ["Port", "OutDataTypeStr", "Unit"],
    "SubSystem": ["TreatAsAtomicUnit"],
    "Integrator": ["InitialCondition", "GainValue"],
    "TransferFcn": ["Numerator", "Denominator"]
  }
}
```

Capture algorithm:
1. `blocks = find_system(modelName, 'LookUnderMasks','all', 'FollowLinks','off', 'Type','block')` — exclude the model root itself if present; skip `BlockType` in `{'Annotation'}` if any.
2. For each block path: `get_param` for `BlockType`, `MaskType`, `Name`; params = common ∪ byBlockType{BlockType}; for each param, `try get_param`, on failure skip; store `char(string(value))`.
3. Do **not** read `Position` or font params.
4. Lines: for each block, `lh = get_param(blk,'LineHandles');` for each outbound line handle `>0`, read `SrcBlock`/`SrcPort`/`DstBlock`/`DstPort` (handle vector destinations); build canonical `src`/`dst` strings; dedupe.
5. Set `modelPath` via `get_param(modelName,'FileName')`.

- [ ] **Step 1: Write whitelist load test**

```matlab
classdef tLoadWhitelist < matlab.unittest.TestCase
    methods (Test)
        function loadsGainParams(testCase)
            setupPath();
            wl = model_log.loadWhitelist();
            testCase.verifyTrue(any(strcmp(wl.common, 'SampleTime')));
            testCase.verifyTrue(any(strcmp(wl.byBlockType.Gain, 'Gain')));
        end
    end
end
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement `loadWhitelist` (path relative to package: `fullfile(fileparts(fileparts(mfilename('fullpath'))),'config','param_whitelist.json')`) and `captureSnapshot`**

- [ ] **Step 4: Run whitelist test PASS; manually smoke in MATLAB:**

```matlab
setupPath();
new_system('MCL_Tmp'); open_system('MCL_Tmp');
add_block('simulink/Math Operations/Gain','MCL_Tmp/G1');
set_param('MCL_Tmp/G1','Gain','3');
snap = model_log.captureSnapshot('MCL_Tmp');
assert(snap.blocks.isKey('MCL_Tmp/G1'));
assert(strcmp(snap.blocks('MCL_Tmp/G1').params.Gain,'3'));
close_system('MCL_Tmp',0);
```

- [ ] **Step 5: Commit only if user asked**

---

### Task 5: State I/O + enable/disable + callbacks

**Files:**
- Create: `+model_log/loadState.m`
- Create: `+model_log/saveState.m`
- Create: `+model_log/resolveModel.m` (full)
- Create: `+model_log/installCallbacks.m`
- Create: `+model_log/onPreSave.m`
- Create: `+model_log/onPostSave.m`
- Create: `+model_log/enable.m`
- Create: `+model_log/disable.m`
- Create: `+model_log/isEnabled.m`
- Create: `start_model_log.m`

**Interfaces:**
- Consumes: Tasks 1–4
- Produces public API from spec:
  - `model_log.enable(model)` — `model` optional, default `bdroot`
  - `model_log.disable(model, 'KeepState', true)`
  - `tf = model_log.isEnabled(model)`
  - Callbacks invoke `model_log.onPreSave(modelName)` / `model_log.onPostSave(modelName)`

**Callback install rules:**
- Read `get_param(model,'PreSaveFcn')` / `PostSaveFcn` into state.
- Set:
  - Pre: `model_log.onPreSave(bdroot); <original>`
  - Post: `model_log.onPostSave(bdroot); <original>`  
  If original empty, only tool call. Use model name string baked at enable time if `bdroot` in callback string is unreliable — prefer storing `modelName` in the callback: `model_log.onPostSave('MyModel');`.

**`onPostSave` sequence (all in try/catch → `warning`):**
1. `[~, statePath] = statePaths(get_param(model,'FileName'))`; load state; if missing/corrupt → rebuild baseline snapshot, append Chinese warning section to Log, save state, return.
2. `newSnap = captureSnapshot(model)`
3. `changes = diffSnapshots(state.snapshot, newSnap)`
4. If not empty: `appendLog` with `meta.timestamp = datestr(now,31)`, `meta.user = getenv('USERNAME')` (Windows) / `getenv('USER')`, `meta.modelName`
5. `state.snapshot = newSnap`; saveState

**`enable`:** resolve → load_system → capture baseline → save state enabled=true with originals → installCallbacks. Do not append change section.

**`disable`:** restore originals from state → set enabled false or delete state if `KeepState` false.

- [ ] **Step 1: Write Simulink smoke test `tests/tEnableDisableSmoke.m`**

```matlab
classdef tEnableDisableSmoke < matlab.unittest.TestCase
    properties
        WorkDir
        ModelName = 'MCL_Smoke'
    end
    methods (TestMethodSetup)
        function createModel(testCase)
            setupPath();
            testCase.WorkDir = tempname; mkdir(testCase.WorkDir);
            modelPath = fullfile(testCase.WorkDir, [testCase.ModelName '.slx']);
            new_system(testCase.ModelName); open_system(testCase.ModelName);
            add_block('simulink/Sources/In1', [testCase.ModelName '/In1']);
            add_block('simulink/Math Operations/Gain', [testCase.ModelName '/G1']);
            add_block('simulink/Sinks/Out1', [testCase.ModelName '/Out1']);
            set_param([testCase.ModelName '/G1'], 'Gain', '1');
            add_line(testCase.ModelName, 'In1/1', 'G1/1');
            add_line(testCase.ModelName, 'G1/1', 'Out1/1');
            save_system(testCase.ModelName, modelPath);
        end
    end
    methods (TestMethodTeardown)
        function cleanup(testCase)
            if bdIsLoaded(testCase.ModelName)
                close_system(testCase.ModelName, 0);
            end
            if isfolder(testCase.WorkDir)
                rmdir(testCase.WorkDir, 's');
            end
        end
    end
    methods (Test)
        function logsGainChangeOnSave(testCase)
            model_log.enable(testCase.ModelName);
            testCase.verifyTrue(model_log.isEnabled(testCase.ModelName));
            set_param([testCase.ModelName '/G1'], 'Gain', '2.5');
            save_system(testCase.ModelName);
            logPath = fullfile(testCase.WorkDir, [testCase.ModelName '_model_log.md']);
            testCase.verifyTrue(isfile(logPath));
            txt = fileread(logPath);
            testCase.verifyTrue(contains(txt, '### 参数变更'));
            testCase.verifyTrue(contains(txt, '2.5'));
            model_log.disable(testCase.ModelName);
            testCase.verifyFalse(model_log.isEnabled(testCase.ModelName));
            set_param([testCase.ModelName '/G1'], 'Gain', '9');
            save_system(testCase.ModelName);
            txt2 = fileread(logPath);
            testCase.verifyFalse(contains(txt2, '''9''') || contains(txt2, '| `9`') || contains(txt2, '| 9 |'));
            % After disable, no new param section for 9 — compare file length or count of 参数变更
            testCase.verifyEqual(count(txt2, '### 参数变更'), count(txt, '### 参数变更'));
        end
    end
end
```

- [ ] **Step 2: Run smoke test — expect FAIL**

- [ ] **Step 3: Implement resolve/state/callbacks/enable/disable/onPostSave/onPreSave/start script**

`start_model_log.m`:
```matlab
setupPath();
model_log.enable(bdroot);
fprintf('Model log enabled for %s\n', bdroot);
```

- [ ] **Step 4: Run `tEnableDisableSmoke` — expect PASS**

Also verify acceptance cases from spec manually or as extra test methods in same class:
- Add/remove block + rewire → subsections appear
- Change only `Position` → no new section
- Delete state file → warning section + save succeeds

- [ ] **Step 5: Commit only if user asked**

---

### Task 6: Example script + README usage

**Files:**
- Create: `examples/demo_model_log.m`
- Create: `README.md` (short: purpose, setupPath, enable, where logs appear, disable)

**Interfaces:**
- Consumes: public API
- Produces: runnable demo that prints path to generated markdown

- [ ] **Step 1: Write `examples/demo_model_log.m`** that creates a temp model, enables logging, changes Gain, saves, `fprintf` the Log path, opens with `edit(logPath)` optional

- [ ] **Step 2: Run demo in MATLAB — expect Log file with one 参数变更 section**

- [ ] **Step 3: Write `README.md` with:**
  1. `setupPath`
  2. Open model → `start_model_log` or `model_log.enable`
  3. Edit + save → read `*_model_log.md`
  4. `model_log.disable`

- [ ] **Step 4: Run full unit suite**

```matlab
cd('D:\98_Github\Model_change_log'); setupPath();
r = runtests('tests');
assert(all([r.Passed]))
```

Expected: all PASS.

- [ ] **Step 5: Commit only if user asked**

---

## Spec coverage checklist

| Spec item | Task |
|-----------|------|
| R1 save trigger via PostSaveFcn | Task 5 |
| R2 structure + whitelist params | Tasks 2, 4 |
| R3 sidecar md beside slx | Tasks 1, 3 |
| R4 append history | Task 3 |
| R5 manual enable m-file | Task 5 (`start_model_log.m`) |
| R6 never block save | Task 5 `onPostSave` try/catch |
| R7 ignore layout | Task 4 capture omits Position |
| Baseline on enable, no first section | Task 5 |
| Chain existing callbacks | Task 5 `installCallbacks` |
| State corrupt rebuild + warning | Task 5 |
| Chinese Markdown template | Task 3 |
| param_whitelist.json extensible | Task 4 |
| Acceptance tests | Tasks 2–6 |

## Self-review notes

- No TBD placeholders left in tasks.
- `blockAdded` represented as cell of structs with `.path` / `.blockType` consistently in Tasks 2–3–5.
- Commits gated on explicit user request per workspace git rules.

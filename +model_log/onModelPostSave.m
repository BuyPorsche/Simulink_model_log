function onModelPostSave(modelName)
%ONMODELPOSTSAVE Global save handler: snapshot diff and append Markdown.

    try
        if ~model_log.isGloballyEnabled()
            return;
        end

        modelName = char(string(modelName));
        if ~bdIsLoaded(modelName)
            return;
        end
        if strcmpi(get_param(modelName, 'BlockDiagramType'), 'library')
            return;
        end

        modelPath = char(string(get_param(modelName, 'FileName')));
        if isempty(modelPath)
            return;
        end

        [logPath, statePath] = model_log.statePaths(modelPath);
        state = model_log.loadState(statePath);
        newSnap = model_log.captureSnapshot(modelName);
        firstLogFile = ~isfile(logPath);

        if isempty(fieldnames(state)) || ~isfield(state, 'snapshot') || ...
                ~model_log.isUsableSnapshot(state.snapshot)
            state.enabled = true;
            state.toolVersion = model_log.toolVersion();
            state.enabledAt = model_log.timestampNow();
            state.snapshot = newSnap;
            state.version = 0;
            if firstLogFile
                state.baselineReason = 'no_log_md';
            end
            model_log.saveState(statePath, state);
            return;
        end

        oldSnap = model_log.unpackSnapshot(state.snapshot);
        changes = model_log.diffSnapshots(oldSnap, newSnap);

        % Whole-model "all blocks are new" (incl. full key remapping) must not
        % dump every block into the first markdown log.
        if model_log.isFullModelResync(changes, newSnap)
            if firstLogFile
                changes = model_log.stripMassStructuralChanges(changes);
                if model_log.isEmptyChanges(changes)
                    state.enabled = true;
                    state.toolVersion = model_log.toolVersion();
                    state.snapshot = newSnap;
                    state.version = 0;
                    state.baselineReason = 'resync_no_log_md';
                    model_log.saveState(statePath, state);
                    return;
                end
                % Keep only non-structural edits (params / lines / chart internals).
            else
                % Existing history: still avoid spammy full-model add lists.
                changes = model_log.stripMassStructuralChanges(changes);
                if model_log.isEmptyChanges(changes)
                    state.snapshot = newSnap;
                    state.enabled = true;
                    model_log.saveState(statePath, state);
                    return;
                end
            end
        end

        if ~model_log.isEmptyChanges(changes)
            meta.timestamp = model_log.timestampNow();
            meta.user = localUserName();
            meta.modelName = modelName;
            meta.version = localNextVersion(state, logPath);
            model_log.appendLog(logPath, meta, changes);
            state.version = meta.version;
        end

        state.snapshot = newSnap;
        state.enabled = true;
        model_log.saveState(statePath, state);
    catch ME
        warning('model_log:onModelPostSave:Failed', '%s', ME.message);
    end
end

function v = localNextVersion(state, logPath)
    % Changelog version counter: 0 at baseline, +1 per logged save.
    if isfield(state, 'version') && isnumeric(state.version) && ...
            ~isempty(state.version) && isfinite(state.version)
        v = floor(state.version) + 1;
        return;
    end
    % Legacy state (no version field): backfill by counting existing sections
    % in the Markdown log so history is not lost, then +1 for this save.
    v = 1;
    try
        if isfile(logPath)
            txt = fileread(logPath);
            n = numel(regexp(txt, '(?m)^## .+'));
            if n > 0
                v = n + 1;
            end
        end
    catch
    end
end

function name = localUserName()
    name = getenv('USERNAME');
    if isempty(name)
        name = getenv('USER');
    end
    if isempty(name)
        name = 'unknown';
    end
end

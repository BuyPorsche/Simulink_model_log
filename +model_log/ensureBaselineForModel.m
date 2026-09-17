function ensureBaselineForModel(modelName)
%ENSUREBASELINEFORMODEL Capture baseline snapshot when needed.
%
% Rules:
% - Missing/unusable/empty snapshot → capture baseline.
% - Missing *_model_log.md and no baseline yet → capture baseline once.
% - Missing *_model_log.md but baseline already exists → keep it (do not
%   refresh after the user has started editing).
% - Never writes the Markdown log file.

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

    noLogFile = ~isfile(logPath);
    hasBaseline = isfield(state, 'snapshot') && model_log.isUsableSnapshot(state.snapshot);

    if hasBaseline && noLogFile
        % Keep the open-time baseline until the first real logged save.
        return;
    end

    badSnapshot = isempty(fieldnames(state)) || ~hasBaseline;
    if ~(noLogFile || badSnapshot)
        return;
    end

    state.enabled = true;
    state.toolVersion = model_log.toolVersion();
    state.enabledAt = model_log.timestampNow();
    state.snapshot = model_log.captureSnapshot(modelName);
    state.version = 0;
    if noLogFile
        state.baselineReason = 'no_log_md';
    else
        state.baselineReason = 'missing_or_empty_snapshot';
    end
    model_log.saveState(statePath, state);
end

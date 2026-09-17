function state = loadState(statePath)
%LOADSTATE Load model-log state MAT file. Returns empty struct if missing.

    state = struct();
    if ~isfile(statePath)
        return;
    end
    try
        data = load(statePath, 'state');
        if isfield(data, 'state')
            state = data.state;
            if isfield(state, 'snapshot')
                state.snapshot = model_log.unpackSnapshot(state.snapshot);
            end
        end
    catch
        state = struct();
    end
end

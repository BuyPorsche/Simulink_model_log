function saveState(statePath, state)
%SAVESTATE Write model-log state MAT file beside the model.

    folder = fileparts(statePath);
    if ~isempty(folder) && ~isfolder(folder)
        mkdir(folder);
    end
    if isfield(state, 'snapshot')
        state.snapshot = model_log.packSnapshot(state.snapshot);
    end
    save(statePath, 'state', '-mat');
end

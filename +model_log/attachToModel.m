function attachToModel(modelName)
%ATTACHTOMODEL Attach save/load listeners and ensure baseline when needed.

    modelName = char(string(modelName));
    if ~bdIsLoaded(modelName)
        return;
    end
    if strcmpi(get_param(modelName, 'BlockDiagramType'), 'library')
        return;
    end

    if localHasLiveListener(modelName)
        model_log.ensureBaselineForModel(modelName);
        return;
    end

    % Stale entry after close/reopen — drop and rebind to the new diagram object.
    model_log.detachFromModel(modelName);

    h = get_param(modelName, 'Object');
    Lsave = Simulink.listener(h, 'PostSaveEvent', @model_log.onModelPostSaveEvent);
    Lload = Simulink.listener(h, 'PostLoadEvent', @model_log.onModelPostLoadEvent);
    closedName = modelName; % capture now; src.Name is invalid during destroy
    Lclose = Simulink.listener(h, 'ObjectBeingDestroyed', ...
        @(~, ~) model_log.onModelDestroyed(closedName));
    model_log.listenerRegistry('putModel', modelName, struct( ...
        'postSave', Lsave, ...
        'postLoad', Lload, ...
        'destroy', Lclose));

    model_log.ensureBaselineForModel(modelName);
end

function tf = localHasLiveListener(modelName)
    tf = false;
    reg = model_log.listenerRegistry('get');
    if ~isKey(reg.modelListeners, modelName)
        return;
    end
    entry = reg.modelListeners(modelName);
    L = localPostSaveListener(entry);
    if isempty(L) || ~isvalid(L)
        return;
    end
    try
        src = L.Source{1};
        tf = isvalid(src) && strcmp(src.Name, modelName) && ...
            src.Handle == get_param(modelName, 'Handle');
    catch
        tf = false;
    end
end

function L = localPostSaveListener(entry)
    if isstruct(entry) && isfield(entry, 'postSave')
        L = entry.postSave;
    else
        L = entry;
    end
end

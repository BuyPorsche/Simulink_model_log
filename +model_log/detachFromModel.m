function detachFromModel(modelName)
%DETACHFROMMODEL Remove PostSave/close listeners for one model.

    modelName = char(string(modelName));
    reg = model_log.listenerRegistry('get');
    if ~isKey(reg.modelListeners, modelName)
        return;
    end
    entry = reg.modelListeners(modelName);
    localDeleteListener(entry, 'postSave');
    localDeleteListener(entry, 'postLoad');
    localDeleteListener(entry, 'destroy');
    if ~isstruct(entry)
        if ~isempty(entry) && isvalid(entry)
            delete(entry);
        end
    end
    model_log.listenerRegistry('removeModel', modelName);
end

function localDeleteListener(entry, fieldName)
    if ~isstruct(entry) || ~isfield(entry, fieldName)
        return;
    end
    L = entry.(fieldName);
    if ~isempty(L) && isvalid(L)
        delete(L);
    end
end

function deferredAttach(modelName)
%DEFERREDATTACH Attach listener after ObjectChildAdded has fully unwound.

    try
        if ~model_log.isGloballyEnabled()
            return;
        end
        model_log.attachToModel(modelName);
    catch ME
        warning('model_log:deferredAttach:Failed', '%s', ME.message);
    end
end

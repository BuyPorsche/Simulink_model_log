function onModelPostLoad(modelName)
%ONMODELPOSTLOAD After load: if no log md exists, save current baseline state.

    try
        if ~model_log.isGloballyEnabled()
            return;
        end
        model_log.ensureBaselineForModel(modelName);
    catch ME
        warning('model_log:onModelPostLoad:Failed', '%s', ME.message);
    end
end

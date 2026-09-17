function onModelPostLoadEvent(src, ~)
%ONMODELPOSTLOADEVENT Listener entrypoint for Simulink PostLoadEvent.

    try
        modelName = src.Name;
    catch
        return;
    end
    model_log.onModelPostLoad(modelName);
end

function onModelPostSaveEvent(src, ~)
%ONMODELPOSTSAVEEVENT Listener entrypoint for Simulink PostSaveEvent.

    try
        modelName = src.Name;
    catch
        return;
    end
    model_log.onModelPostSave(modelName);
end

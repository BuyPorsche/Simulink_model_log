function onModelDestroyed(modelName)
%ONMODELDESTROYED Clear stale listener registry entry when a model closes.

    try
        model_log.listenerRegistry('removeModel', char(string(modelName)));
    catch
    end
end

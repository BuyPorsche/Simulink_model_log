function disable()
%DISABLE Disable session-wide model log and remove listeners.

    model_log.setGloballyEnabled(false);

    reg = model_log.listenerRegistry('get');
    modelNames = reg.modelListeners.keys();
    for i = 1:numel(modelNames)
        model_log.detachFromModel(modelNames{i});
    end

    model_log.cleanupRootListener();
    model_log.listenerRegistry('clear');
end

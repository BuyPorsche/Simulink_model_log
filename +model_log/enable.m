function enable()
%ENABLE Enable model log for every model saved in this MATLAB session.

    setupPath();

    if ~model_log.isGloballyEnabled()
        model_log.setGloballyEnabled(true);
    end

    model_log.ensureRootListener();
    model_log.attachToLoadedModels();
end

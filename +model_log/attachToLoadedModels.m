function attachToLoadedModels()
%ATTACHTOLOADEDMODELS Attach listeners/baselines to all loaded non-library models.

    bds = Simulink.allBlockDiagrams('model');
    if isempty(bds)
        return;
    end
    names = cellstr(string(get_param(bds, 'Name')));
    for i = 1:numel(names)
        model_log.attachToModel(names{i});
    end
end

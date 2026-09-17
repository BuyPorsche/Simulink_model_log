function [logPath, statePath] = statePaths(modelPath)
%STATEPATHS Return Log.md and hidden state.mat paths beside the model file.

    [folder, name, ~] = fileparts(modelPath);
    logPath = fullfile(folder, [name '_model_log.md']);
    statePath = fullfile(folder, ['.' name '_model_log_.mat']);
end

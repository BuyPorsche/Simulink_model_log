function setupPath()
%SETUPPATH Add repository root to the MATLAB path so +model_log resolves.

    root = fileparts(mfilename('fullpath'));
    addpath(root);
end

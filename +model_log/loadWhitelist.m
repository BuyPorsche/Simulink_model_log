function wl = loadWhitelist()
%LOADWHITELIST Load parameter whitelist JSON from config/param_whitelist.json.

    pkgDir = fileparts(mfilename('fullpath'));
    rootDir = fileparts(pkgDir);
    jsonPath = fullfile(rootDir, 'config', 'param_whitelist.json');
    if ~isfile(jsonPath)
        error('model_log:loadWhitelist:MissingFile', ...
            'Whitelist file not found: %s', jsonPath);
    end
    raw = jsondecode(fileread(jsonPath));
    if isfield(raw, 'common')
        wl.common = cellstr(string(raw.common(:)));
    else
        wl.common = {};
    end
    if isfield(raw, 'ignore')
        wl.ignore = cellstr(string(raw.ignore(:)));
    else
        wl.ignore = {};
    end
    wl.byBlockType = struct();
    if isfield(raw, 'byBlockType')
        types = fieldnames(raw.byBlockType);
        for i = 1:numel(types)
            t = types{i};
            wl.byBlockType.(t) = cellstr(string(raw.byBlockType.(t)(:)));
        end
    end
end

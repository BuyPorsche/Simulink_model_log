function v = toolVersion()
%TOOLVERSION Return model_log version from repo VERSION file.

    persistent cachedVersion
    if ~isempty(cachedVersion)
        v = cachedVersion;
        return;
    end

    v = 'V0.0';
    try
        pkgDir = fileparts(mfilename('fullpath'));
        rootDir = fileparts(pkgDir);
        versionFile = fullfile(rootDir, 'VERSION');
        if isfile(versionFile)
            txt = strtrim(fileread(versionFile));
            lines = regexp(txt, '\r\n|\n|\r', 'split');
            if ~isempty(lines) && ~isempty(strtrim(lines{1}))
                v = char(strtrim(string(lines{1})));
            end
        end
    catch
        % Keep fallback.
    end
    cachedVersion = v;
end

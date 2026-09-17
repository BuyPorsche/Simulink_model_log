function s = paramValueToString(val)
%PARAMVALUETOSTRING Normalize a Simulink parameter value for snapshot compare.

    if ischar(val) || isstring(val)
        s = char(string(val));
        return;
    end
    if isnumeric(val) || islogical(val)
        s = mat2str(val);
        return;
    end
    if iscell(val)
        parts = cell(size(val));
        for i = 1:numel(val)
            parts{i} = model_log.paramValueToString(val{i});
        end
        s = strjoin(parts(:)', ' | ');
        return;
    end
    try
        s = jsonencode(val);
    catch
        try
            s = char(string(val));
        catch
            s = '<unprintable>';
        end
    end
end

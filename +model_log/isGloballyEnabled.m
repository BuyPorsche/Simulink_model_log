function tf = isGloballyEnabled()
%ISGLOBALLYENABLED True when session-wide Log logging is on.

    v = getappdata(0, 'model_log_enabled');
    if isempty(v)
        tf = false;
    else
        tf = logical(v);
    end
end

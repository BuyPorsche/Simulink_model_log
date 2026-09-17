function setGloballyEnabled(tf)
%SETGLOBALLYENABLED Store session-wide enable flag on groot appdata.

    setappdata(0, 'model_log_enabled', logical(tf));
end

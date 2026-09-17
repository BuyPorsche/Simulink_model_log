function tf = isEnabled()
%ISENABLED True when session-wide model log is enabled.

    tf = model_log.isGloballyEnabled();
end

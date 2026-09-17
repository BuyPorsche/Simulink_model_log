function cleanupRootListener()
%CLEANUPROOTLISTENER Delete tracked ObjectChildAdded root listener if present.

    try
        if isappdata(0, 'model_log_rootListener')
            L = getappdata(0, 'model_log_rootListener');
            if ~isempty(L) && isvalid(L)
                delete(L);
            end
            rmappdata(0, 'model_log_rootListener');
        end
    catch
    end

    try
        reg = model_log.listenerRegistry('get');
        if ~isempty(reg.rootListener) && isvalid(reg.rootListener)
            delete(reg.rootListener);
        end
        reg.rootListener = [];
        model_log.listenerRegistry('set', reg);
    catch
    end
end

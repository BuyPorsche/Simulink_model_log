function ensureRootListener()
%ENSUREROOTLISTENER Create ObjectChildAdded listener if missing or invalid.

    reg = model_log.listenerRegistry('get');
    if ~isempty(reg.rootListener) && isvalid(reg.rootListener)
        setappdata(0, 'model_log_rootListener', reg.rootListener);
        return;
    end

    model_log.cleanupRootListener();
    reg = model_log.listenerRegistry('get');
    reg.rootListener = addlistener(slroot, 'ObjectChildAdded', ...
        @model_log.onRootChildAdded);
    model_log.listenerRegistry('set', reg);
    setappdata(0, 'model_log_rootListener', reg.rootListener);
end

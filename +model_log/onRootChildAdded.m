function onRootChildAdded(~, eventData)
%ONROOTCHILDADDED Schedule attach after ObjectChildAdded finishes.

    try
        if ~model_log.isGloballyEnabled()
            return;
        end
        child = eventData.Child;
        if ~isa(child, 'Simulink.BlockDiagram')
            return;
        end
        modelName = child.Name;
        % PostSave listeners created inside ObjectChildAdded do not fire;
        % defer to the next timer tick (after this event unwinds).
        t = timer( ...
            'ExecutionMode', 'singleShot', ...
            'StartDelay', 0.2, ...
            'TimerFcn', @(~, ~) model_log.deferredAttach(modelName));
        model_log.retainTimer(t);
        start(t);
    catch ME
        warning('model_log:onRootChildAdded:Failed', '%s', ME.message);
    end
end

function retainTimer(t)
%RETAINTIMER Keep timer references so single-shot callbacks are not GC'd.

    persistent timers
    if isempty(timers)
        timers = {};
    end
    % Drop invalid timers
    keep = {};
    for i = 1:numel(timers)
        if isvalid(timers{i})
            keep{end+1} = timers{i}; %#ok<AGROW>
        end
    end
    keep{end+1} = t;
    timers = keep;
end

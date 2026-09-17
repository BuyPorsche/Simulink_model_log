function sfChanges = diffStateflow(oldCharts, newCharts)
%DIFFSTATEFLOW Diff Stateflow chart snapshots into typed change records.

    sfChanges = emptySfChanges();
    oldCharts = localEnsureMap(oldCharts);
    newCharts = localEnsureMap(newCharts);

    oldKeys = localKeys(oldCharts);
    newKeys = localKeys(newCharts);
    onlyOld = setdiff(oldKeys, newKeys);
    onlyNew = setdiff(newKeys, oldKeys);
    both = intersect(oldKeys, newKeys);

    for i = 1:numel(onlyNew)
        c = newCharts(onlyNew{i});
        sfChanges.chartAdded{end+1} = struct( ...
            'path', onlyNew{i}, ...
            'name', localField(c, 'name'), ...
            'stateCount', localCount(c, 'states'), ...
            'transitionCount', localCount(c, 'transitions'), ...
            'dataCount', localCount(c, 'data')); %#ok<AGROW>
    end
    for i = 1:numel(onlyOld)
        c = oldCharts(onlyOld{i});
        sfChanges.chartRemoved{end+1} = struct( ...
            'path', onlyOld{i}, ...
            'name', localField(c, 'name'), ...
            'stateCount', localCount(c, 'states'), ...
            'transitionCount', localCount(c, 'transitions'), ...
            'dataCount', localCount(c, 'data')); %#ok<AGROW>
    end

    for i = 1:numel(both)
        path = both{i};
        oldC = unpackChart(oldCharts(path));
        newC = unpackChart(newCharts(path));
        sfChanges = localDiffMap(sfChanges, path, oldC.states, newC.states, 'state');
        sfChanges = localDiffMap(sfChanges, path, oldC.transitions, newC.transitions, 'transition');
        sfChanges = localDiffMap(sfChanges, path, oldC.data, newC.data, 'data');
    end
end

function n = localCount(chart, fieldName)
    n = 0;
    if ~isstruct(chart) || ~isfield(chart, fieldName)
        return;
    end
    m = chart.(fieldName);
    if isa(m, 'containers.Map')
        n = m.Count;
    elseif isstruct(m) && isfield(m, 'keys')
        n = numel(m.keys);
    end
end

function sfChanges = localDiffMap(sfChanges, chartPath, oldMap, newMap, kind)
    oldMap = localEnsureMap(oldMap);
    newMap = localEnsureMap(newMap);
    oldKeys = localKeys(oldMap);
    newKeys = localKeys(newMap);
    onlyOld = setdiff(oldKeys, newKeys);
    onlyNew = setdiff(newKeys, oldKeys);
    both = intersect(oldKeys, newKeys);

    addedField = [kind 'Added'];
    removedField = [kind 'Removed'];
    changedField = [kind 'Changed'];

    for i = 1:numel(onlyNew)
        sfChanges.(addedField){end+1} = localRecord(chartPath, kind, onlyNew{i}, newMap(onlyNew{i})); %#ok<AGROW>
    end
    for i = 1:numel(onlyOld)
        sfChanges.(removedField){end+1} = localRecord(chartPath, kind, onlyOld{i}, oldMap(onlyOld{i})); %#ok<AGROW>
    end
    for i = 1:numel(both)
        key = both{i};
        oldItem = oldMap(key);
        newItem = newMap(key);
        fields = localContentFields(kind);
        for f = 1:numel(fields)
            fname = fields{f};
            ov = localField(oldItem, fname);
            nv = localField(newItem, fname);
            if ~strcmp(ov, nv)
                ch.path = chartPath;
                ch.kind = kind;
                ch.key = key;
                ch.displayName = localDisplayName(kind, newItem, key);
                ch.field = fname;
                ch.oldValue = ov;
                ch.newValue = nv;
                sfChanges.(changedField)(end+1) = ch; %#ok<AGROW>
            end
        end
    end
end

function fields = localContentFields(kind)
    switch kind
        case 'state'
            fields = {'name', 'label', 'decomposition'};
        case 'transition'
            fields = {'label', 'srcKey', 'dstKey', 'srcName', 'dstName'};
        case 'data'
            fields = {'name', 'scope', 'dataType'};
        otherwise
            fields = {};
    end
end

function rec = localRecord(chartPath, kind, key, item)
    rec.chartPath = chartPath;
    rec.kind = kind;
    rec.key = key;
    rec.displayName = localDisplayName(kind, item, key);
    switch kind
        case 'state'
            rec.label = localField(item, 'label');
        case 'transition'
            rec.label = localField(item, 'label');
            rec.srcName = localField(item, 'srcName');
            rec.dstName = localField(item, 'dstName');
        case 'data'
            rec.scope = localField(item, 'scope');
            rec.dataType = localField(item, 'dataType');
        otherwise
    end
end

function name = localDisplayName(kind, item, key)
    switch kind
        case 'state'
            name = localField(item, 'name');
        case 'transition'
            name = sprintf('%s -> %s', localField(item, 'srcName'), localField(item, 'dstName'));
            if strlength(string(name)) == 0 || strcmp(name, ' -> ')
                name = key;
            end
        case 'data'
            name = localField(item, 'name');
        otherwise
            name = key;
    end
    if strlength(string(name)) == 0
        name = key;
    end
end

function chart = unpackChart(chart)
    if ~isstruct(chart)
        chart = struct('states', containers.Map(), 'transitions', containers.Map(), 'data', containers.Map());
        return;
    end
    chart.states = localEnsureMap(localFieldRaw(chart, 'states'));
    chart.transitions = localEnsureMap(localFieldRaw(chart, 'transitions'));
    chart.data = localEnsureMap(localFieldRaw(chart, 'data'));
end

function m = localEnsureMap(m)
    if isa(m, 'containers.Map')
        return;
    end
    m = containers.Map('KeyType', 'char', 'ValueType', 'any');
end

function keysOut = localKeys(m)
    keysOut = {};
    if ~isa(m, 'containers.Map') || m.Count == 0
        return;
    end
    keysOut = cellstr(string(m.keys()));
    keysOut = keysOut(:)';
end

function v = localField(s, name)
    v = '';
    if isstruct(s) && isfield(s, name)
        v = char(string(s.(name)));
    end
end

function v = localFieldRaw(s, name)
    v = [];
    if isstruct(s) && isfield(s, name)
        v = s.(name);
    end
end

function sfChanges = emptySfChanges()
    sfChanges.chartAdded = {};
    sfChanges.chartRemoved = {};
    sfChanges.stateAdded = {};
    sfChanges.stateRemoved = {};
    sfChanges.stateChanged = struct('path', {}, 'kind', {}, 'key', {}, 'displayName', {}, 'field', {}, 'oldValue', {}, 'newValue', {});
    sfChanges.transitionAdded = {};
    sfChanges.transitionRemoved = {};
    sfChanges.transitionChanged = struct('path', {}, 'kind', {}, 'key', {}, 'displayName', {}, 'field', {}, 'oldValue', {}, 'newValue', {});
    sfChanges.dataAdded = {};
    sfChanges.dataRemoved = {};
    sfChanges.dataChanged = struct('path', {}, 'kind', {}, 'key', {}, 'displayName', {}, 'field', {}, 'oldValue', {}, 'newValue', {});
end

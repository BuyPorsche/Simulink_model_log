function changes = diffSnapshots(oldSnap, newSnap)
%DIFFSNAPSHOTS Compare two model snapshots and return typed change records.

    changes = emptyChanges();

    oldSnap = model_log.unpackSnapshot(oldSnap);
    newSnap = model_log.unpackSnapshot(newSnap);
    oldKeys = localKeyList(oldSnap.blocks);
    newKeys = localKeyList(newSnap.blocks);

    onlyOld = setdiff(oldKeys, newKeys);
    onlyNew = setdiff(newKeys, oldKeys);
    both = intersect(oldKeys, newKeys);

    for i = 1:numel(onlyNew)
        b = newSnap.blocks(onlyNew{i});
        changes.blockAdded{end+1} = struct( ...
            'path', onlyNew{i}, ...
            'blockType', localBlockType(b)); %#ok<AGROW>
    end

    for i = 1:numel(onlyOld)
        b = oldSnap.blocks(onlyOld{i});
        changes.blockRemoved{end+1} = struct( ...
            'path', onlyOld{i}, ...
            'blockType', localBlockType(b)); %#ok<AGROW>
    end

    for i = 1:numel(both)
        path = both{i};
        oldB = oldSnap.blocks(path);
        newB = newSnap.blocks(path);
        oldType = localBlockType(oldB);
        newType = localBlockType(newB);
        if ~strcmp(oldType, newType)
            changes.blockTypeChanged(end+1) = struct( ...
                'path', path, 'oldType', oldType, 'newType', newType); %#ok<AGROW>
            continue;
        end
        oldParams = localParamNames(oldB);
        newParams = localParamNames(newB);
        paramNames = unique([oldParams, newParams]);
        for p = 1:numel(paramNames)
            pname = paramNames{p};
            oldVal = localParamValue(oldB, pname);
            newVal = localParamValue(newB, pname);
            if ~strcmp(oldVal, newVal)
                changes.paramChanged(end+1) = struct( ...
                    'path', path, ...
                    'param', pname, ...
                    'oldValue', oldVal, ...
                    'newValue', newVal); %#ok<AGROW>
            end
        end
    end

    oldLineKeys = localLineKeys(oldSnap.lines);
    newLineKeys = localLineKeys(newSnap.lines);
    removed = setdiff(oldLineKeys, newLineKeys);
    added = setdiff(newLineKeys, oldLineKeys);
    for i = 1:numel(removed)
        [src, dst] = localSplitLineKey(removed{i});
        changes.lineRemoved(end+1) = struct('src', src, 'dst', dst); %#ok<AGROW>
    end
    for i = 1:numel(added)
        [src, dst] = localSplitLineKey(added{i});
        changes.lineAdded(end+1) = struct('src', src, 'dst', dst); %#ok<AGROW>
    end

    oldCharts = localCharts(oldSnap);
    newCharts = localCharts(newSnap);
    sfChanges = model_log.diffStateflow(oldCharts, newCharts);
    changes = localMergeSf(changes, sfChanges);
end

function charts = localCharts(snap)
    charts = containers.Map('KeyType', 'char', 'ValueType', 'any');
    if isstruct(snap) && isfield(snap, 'charts')
        charts = snap.charts;
    end
end

function changes = localMergeSf(changes, sfChanges)
    fields = fieldnames(sfChanges);
    for i = 1:numel(fields)
        changes.(fields{i}) = sfChanges.(fields{i});
    end
end

function keyList = localKeyList(blocksMap)
    keyList = {};
    if ~isa(blocksMap, 'containers.Map') || blocksMap.Count == 0
        return;
    end
    keyList = cellstr(string(blocksMap.keys()));
    keyList = keyList(:)';
end

function changes = emptyChanges()
    changes.blockAdded = {};
    changes.blockRemoved = {};
    changes.blockTypeChanged = struct('path', {}, 'oldType', {}, 'newType', {});
    changes.paramChanged = struct('path', {}, 'param', {}, 'oldValue', {}, 'newValue', {});
    changes.lineAdded = struct('src', {}, 'dst', {});
    changes.lineRemoved = struct('src', {}, 'dst', {});
    changes.chartAdded = {};
    changes.chartRemoved = {};
    changes.stateAdded = {};
    changes.stateRemoved = {};
    changes.stateChanged = struct('path', {}, 'kind', {}, 'key', {}, 'displayName', {}, 'field', {}, 'oldValue', {}, 'newValue', {});
    changes.transitionAdded = {};
    changes.transitionRemoved = {};
    changes.transitionChanged = struct('path', {}, 'kind', {}, 'key', {}, 'displayName', {}, 'field', {}, 'oldValue', {}, 'newValue', {});
    changes.dataAdded = {};
    changes.dataRemoved = {};
    changes.dataChanged = struct('path', {}, 'kind', {}, 'key', {}, 'displayName', {}, 'field', {}, 'oldValue', {}, 'newValue', {});
end

function t = localBlockType(b)
    if isfield(b, 'blockType')
        t = char(string(b.blockType));
    else
        t = '';
    end
end

function names = localParamNames(b)
    if ~isfield(b, 'params') || isempty(b.params)
        names = {};
        return;
    end
    names = fieldnames(b.params)';
end

function v = localParamValue(b, pname)
    if ~isfield(b, 'params') || ~isfield(b.params, pname)
        v = '';
        return;
    end
    v = char(string(b.params.(pname)));
end

function keysOut = localLineKeys(lines)
    keysOut = {};
    if isempty(lines)
        return;
    end
    for i = 1:numel(lines)
        keysOut{end+1} = [char(string(lines(i).src)) '||' char(string(lines(i).dst))]; %#ok<AGROW>
    end
    keysOut = unique(keysOut);
end

function [src, dst] = localSplitLineKey(key)
    parts = strsplit(key, '||');
    src = parts{1};
    if numel(parts) > 1
        dst = parts{2};
    else
        dst = '';
    end
end

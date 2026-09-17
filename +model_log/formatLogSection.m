function md = formatLogSection(meta, changes)
%formatLogSection Build one English Markdown section for a save event.

    lines = {};
    rule = repmat('#', 1, 60);
    lines{end+1} = rule; %#ok<AGROW>
    lines{end+1} = sprintf('## %s | Version: %d | User: %s | Model: %s', ...
        meta.timestamp, localMetaVersion(meta), meta.user, meta.modelName); %#ok<AGROW>
    lines{end+1} = rule; %#ok<AGROW>
    lines{end+1} = ''; %#ok<AGROW>

    if ~isempty(changes.blockAdded)
        lines{end+1} = '### Blocks Added'; %#ok<AGROW>
        for i = 1:numel(changes.blockAdded)
            item = changes.blockAdded{i};
            lines{end+1} = sprintf('- `%s` (BlockType: %s)', item.path, item.blockType); %#ok<AGROW>
        end
        lines{end+1} = ''; %#ok<AGROW>
    end

    if ~isempty(changes.blockRemoved)
        lines{end+1} = '### Blocks Removed'; %#ok<AGROW>
        for i = 1:numel(changes.blockRemoved)
            item = changes.blockRemoved{i};
            lines{end+1} = sprintf('- `%s` (BlockType: %s)', item.path, item.blockType); %#ok<AGROW>
        end
        lines{end+1} = ''; %#ok<AGROW>
    end

    if ~isempty(changes.blockTypeChanged)
        lines{end+1} = '### Block Type Changed'; %#ok<AGROW>
        for i = 1:numel(changes.blockTypeChanged)
            item = changes.blockTypeChanged(i);
            lines{end+1} = sprintf('- `%s`: %s → %s', item.path, item.oldType, item.newType); %#ok<AGROW>
        end
        lines{end+1} = ''; %#ok<AGROW>
    end

    if ~isempty(changes.paramChanged)
        lines{end+1} = '### Parameter Changes'; %#ok<AGROW>
        for i = 1:numel(changes.paramChanged)
            item = changes.paramChanged(i);
            lines{end+1} = sprintf('- Block: `%s`', item.path); %#ok<AGROW>
            lines{end+1} = sprintf('  - Param: `%s`', item.param); %#ok<AGROW>
            lines{end+1} = sprintf('  - Old: `%s`', localDisplayValue(item.oldValue)); %#ok<AGROW>
            lines{end+1} = sprintf('  - New: `%s`', localDisplayValue(item.newValue)); %#ok<AGROW>
        end
        lines{end+1} = ''; %#ok<AGROW>
    end

    if ~isempty(changes.lineAdded) || ~isempty(changes.lineRemoved)
        lines{end+1} = '### Line Changes'; %#ok<AGROW>
        for i = 1:numel(changes.lineAdded)
            item = changes.lineAdded(i);
            lines{end+1} = sprintf('- Added: `%s` → `%s`', item.src, item.dst); %#ok<AGROW>
        end
        for i = 1:numel(changes.lineRemoved)
            item = changes.lineRemoved(i);
            lines{end+1} = sprintf('- Removed: `%s` → `%s`', item.src, item.dst); %#ok<AGROW>
        end
        lines{end+1} = ''; %#ok<AGROW>
    end

    sfLines = localFormatStateflow(changes);
    if ~isempty(sfLines)
        lines = [lines, sfLines]; %#ok<AGROW>
    end

    lines{end+1} = '---'; %#ok<AGROW>
    lines{end+1} = ''; %#ok<AGROW>
    md = strjoin(lines, newline);
end

function lines = localFormatStateflow(changes)
    lines = {};
    hasSf = localHas(changes, 'chartAdded') || localHas(changes, 'chartRemoved') || ...
        localHas(changes, 'stateAdded') || localHas(changes, 'stateRemoved') || localHas(changes, 'stateChanged') || ...
        localHas(changes, 'transitionAdded') || localHas(changes, 'transitionRemoved') || localHas(changes, 'transitionChanged') || ...
        localHas(changes, 'dataAdded') || localHas(changes, 'dataRemoved') || localHas(changes, 'dataChanged');
    if ~hasSf
        return;
    end

    lines{end+1} = '### Stateflow Changes'; %#ok<AGROW>

    if localHas(changes, 'chartAdded')
        for i = 1:numel(changes.chartAdded)
            item = changes.chartAdded{i};
            lines{end+1} = sprintf('- Chart Added: `%s` (states %d / transitions %d / data %d)', ...
                item.path, item.stateCount, item.transitionCount, item.dataCount); %#ok<AGROW>
        end
    end
    if localHas(changes, 'chartRemoved')
        for i = 1:numel(changes.chartRemoved)
            item = changes.chartRemoved{i};
            lines{end+1} = sprintf('- Chart Removed: `%s`', item.path); %#ok<AGROW>
        end
    end

    if localHas(changes, 'stateAdded')
        for i = 1:numel(changes.stateAdded)
            item = changes.stateAdded{i};
            lines{end+1} = sprintf('- State Added: `%s` / `%s`', item.chartPath, item.displayName); %#ok<AGROW>
            if isfield(item, 'label') && strlength(string(item.label)) > 0
                lines{end+1} = sprintf('  - Label: `%s`', item.label); %#ok<AGROW>
            end
        end
    end
    if localHas(changes, 'stateRemoved')
        for i = 1:numel(changes.stateRemoved)
            item = changes.stateRemoved{i};
            lines{end+1} = sprintf('- State Removed: `%s` / `%s`', item.chartPath, item.displayName); %#ok<AGROW>
        end
    end
    if localHas(changes, 'stateChanged')
        for i = 1:numel(changes.stateChanged)
            item = changes.stateChanged(i);
            lines{end+1} = sprintf('- State Changed: `%s` / `%s`', item.path, item.displayName); %#ok<AGROW>
            lines{end+1} = sprintf('  - Field: `%s`', localFieldLabel(item.field)); %#ok<AGROW>
            lines{end+1} = sprintf('  - Old: `%s`', localDisplayValue(item.oldValue)); %#ok<AGROW>
            lines{end+1} = sprintf('  - New: `%s`', localDisplayValue(item.newValue)); %#ok<AGROW>
        end
    end

    if localHas(changes, 'transitionAdded')
        for i = 1:numel(changes.transitionAdded)
            item = changes.transitionAdded{i};
            lines{end+1} = sprintf('- Transition Added: `%s` / `%s`', item.chartPath, item.displayName); %#ok<AGROW>
            if isfield(item, 'label') && strlength(string(item.label)) > 0
                lines{end+1} = sprintf('  - Condition/Action: `%s`', item.label); %#ok<AGROW>
            end
        end
    end
    if localHas(changes, 'transitionRemoved')
        for i = 1:numel(changes.transitionRemoved)
            item = changes.transitionRemoved{i};
            lines{end+1} = sprintf('- Transition Removed: `%s` / `%s`', item.chartPath, item.displayName); %#ok<AGROW>
        end
    end
    if localHas(changes, 'transitionChanged')
        for i = 1:numel(changes.transitionChanged)
            item = changes.transitionChanged(i);
            lines{end+1} = sprintf('- Transition Changed: `%s` / `%s`', item.path, item.displayName); %#ok<AGROW>
            lines{end+1} = sprintf('  - Field: `%s`', localFieldLabel(item.field)); %#ok<AGROW>
            lines{end+1} = sprintf('  - Old: `%s`', localDisplayValue(item.oldValue)); %#ok<AGROW>
            lines{end+1} = sprintf('  - New: `%s`', localDisplayValue(item.newValue)); %#ok<AGROW>
        end
    end

    if localHas(changes, 'dataAdded')
        for i = 1:numel(changes.dataAdded)
            item = changes.dataAdded{i};
            lines{end+1} = sprintf('- Data Added: `%s` / `%s` (%s)', ...
                item.chartPath, item.displayName, localFieldOr(item, 'scope', '')); %#ok<AGROW>
        end
    end
    if localHas(changes, 'dataRemoved')
        for i = 1:numel(changes.dataRemoved)
            item = changes.dataRemoved{i};
            lines{end+1} = sprintf('- Data Removed: `%s` / `%s`', item.chartPath, item.displayName); %#ok<AGROW>
        end
    end
    if localHas(changes, 'dataChanged')
        for i = 1:numel(changes.dataChanged)
            item = changes.dataChanged(i);
            lines{end+1} = sprintf('- Data Changed: `%s` / `%s`', item.path, item.displayName); %#ok<AGROW>
            lines{end+1} = sprintf('  - Field: `%s`', localFieldLabel(item.field)); %#ok<AGROW>
            lines{end+1} = sprintf('  - Old: `%s`', localDisplayValue(item.oldValue)); %#ok<AGROW>
            lines{end+1} = sprintf('  - New: `%s`', localDisplayValue(item.newValue)); %#ok<AGROW>
        end
    end

    lines{end+1} = ''; %#ok<AGROW>
end

function v = localMetaVersion(meta)
    % Version counter; defaults to 1 for legacy meta structs without the field.
    if isstruct(meta) && isfield(meta, 'version') && ~isempty(meta.version)
        v = meta.version;
    else
        v = 1;
    end
end

function tf = localHas(changes, name)
    tf = isfield(changes, name) && ~isempty(changes.(name));
end

function s = localFieldLabel(fieldName)
    switch char(string(fieldName))
        case 'label'
            s = 'label/condition';
        case 'name'
            s = 'name';
        case 'decomposition'
            s = 'decomposition';
        case 'srcName'
            s = 'source state';
        case 'dstName'
            s = 'destination state';
        case 'srcKey'
            s = 'source node';
        case 'dstKey'
            s = 'destination node';
        case 'scope'
            s = 'scope';
        case 'dataType'
            s = 'data type';
        otherwise
            s = char(string(fieldName));
    end
end

function v = localFieldOr(item, name, defaultValue)
    if isstruct(item) && isfield(item, name)
        v = char(string(item.(name)));
    else
        v = defaultValue;
    end
end

function s = localDisplayValue(v)
    s = char(string(v));
    if strlength(string(s)) == 0
        s = '(empty)';
    end
end

function snap = unpackSnapshot(snap)
%UNPACKSNAPSHOT Rebuild containers.Map blocks/charts fields from packed storage.

    if ~isstruct(snap)
        snap = struct();
        return;
    end

    if ~(isfield(snap, 'blocks') && isa(snap.blocks, 'containers.Map'))
        m = containers.Map('KeyType', 'char', 'ValueType', 'any');
        if isfield(snap, 'blockPaths') && isfield(snap, 'blockValues')
            paths = cellstr(string(snap.blockPaths(:)));
            vals = snap.blockValues(:);
            n = min(numel(paths), numel(vals));
            for i = 1:n
                m(paths{i}) = vals{i};
            end
        end
        snap.blocks = m;
    end

    if isfield(snap, 'blockPaths')
        snap = rmfield(snap, 'blockPaths');
    end
    if isfield(snap, 'blockValues')
        snap = rmfield(snap, 'blockValues');
    end

    if isfield(snap, 'charts') && isa(snap.charts, 'containers.Map')
        snap.charts = model_log.unpackChartMap(snap.charts);
    elseif isfield(snap, 'chartPaths')
        packed.chartPaths = snap.chartPaths;
        packed.chartValues = snap.chartValues;
        snap.charts = model_log.unpackChartMap(packed);
    else
        snap.charts = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end

    if isfield(snap, 'chartPaths')
        snap = rmfield(snap, 'chartPaths');
    end
    if isfield(snap, 'chartValues')
        snap = rmfield(snap, 'chartValues');
    end
end

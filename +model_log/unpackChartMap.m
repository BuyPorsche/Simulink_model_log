function charts = unpackChartMap(packedOrMap)
%UNPACKCHARTMAP Rebuild charts Map from packed storage or pass through Map.

    charts = containers.Map('KeyType', 'char', 'ValueType', 'any');
    if isa(packedOrMap, 'containers.Map')
        % May still contain nested packed structs after load.
        ks = cellstr(string(packedOrMap.keys()));
        for i = 1:numel(ks)
            charts(ks{i}) = localUnpackOneChart(packedOrMap(ks{i}));
        end
        return;
    end
    if ~isstruct(packedOrMap) || ~isfield(packedOrMap, 'chartPaths')
        return;
    end
    paths = cellstr(string(packedOrMap.chartPaths(:)));
    vals = packedOrMap.chartValues(:);
    n = min(numel(paths), numel(vals));
    for i = 1:n
        charts(paths{i}) = localUnpackOneChart(vals{i});
    end
end

function c = localUnpackOneChart(chart)
    if ~isstruct(chart)
        c = struct( ...
            'path', '', 'name', '', ...
            'states', containers.Map('KeyType', 'char', 'ValueType', 'any'), ...
            'transitions', containers.Map('KeyType', 'char', 'ValueType', 'any'), ...
            'data', containers.Map('KeyType', 'char', 'ValueType', 'any'));
        return;
    end
    c = chart;
    c.states = localUnpackSubMap(localField(chart, 'states'));
    c.transitions = localUnpackSubMap(localField(chart, 'transitions'));
    c.data = localUnpackSubMap(localField(chart, 'data'));
end

function m = localUnpackSubMap(raw)
    m = containers.Map('KeyType', 'char', 'ValueType', 'any');
    if isa(raw, 'containers.Map')
        ks = cellstr(string(raw.keys()));
        for i = 1:numel(ks)
            m(ks{i}) = raw(ks{i});
        end
        return;
    end
    if isstruct(raw) && isfield(raw, 'keys') && isfield(raw, 'values')
        ks = cellstr(string(raw.keys(:)));
        vs = raw.values(:);
        n = min(numel(ks), numel(vs));
        for i = 1:n
            m(ks{i}) = vs{i};
        end
    end
end

function v = localField(s, name)
    v = [];
    if isstruct(s) && isfield(s, name)
        v = s.(name);
    end
end

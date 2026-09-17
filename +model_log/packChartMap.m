function packed = packChartMap(charts)
%PACKCHARTMAP Convert charts Map (with nested Maps) to MAT-friendly cells.

    packed.chartPaths = {};
    packed.chartValues = {};
    if ~isa(charts, 'containers.Map') || charts.Count == 0
        return;
    end
    ks = cellstr(string(charts.keys()));
    packed.chartPaths = ks(:);
    vals = cell(numel(ks), 1);
    for i = 1:numel(ks)
        vals{i} = localPackOneChart(charts(ks{i}));
    end
    packed.chartValues = vals;
end

function c = localPackOneChart(chart)
    c = chart;
    c.states = localPackSubMap(localGetMap(chart, 'states'));
    c.transitions = localPackSubMap(localGetMap(chart, 'transitions'));
    c.data = localPackSubMap(localGetMap(chart, 'data'));
end

function out = localPackSubMap(m)
    out = struct('keys', {{}}, 'values', {{}});
    if ~isa(m, 'containers.Map') || m.Count == 0
        return;
    end
    out.keys = cellstr(string(m.keys()));
    out.keys = out.keys(:);
    out.values = m.values();
    out.values = out.values(:);
end

function m = localGetMap(s, fieldName)
    m = containers.Map('KeyType', 'char', 'ValueType', 'any');
    if isstruct(s) && isfield(s, fieldName) && isa(s.(fieldName), 'containers.Map')
        m = s.(fieldName);
    end
end

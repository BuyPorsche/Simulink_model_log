function charts = captureStateflow(modelName)
%CAPTURESTATEFLOW Capture Stateflow charts (states/transitions/data) in a model.

    charts = containers.Map('KeyType', 'char', 'ValueType', 'any');
    modelName = char(string(modelName));

    if isempty(ver('Stateflow'))
        return;
    end

    try
        rt = sfroot;
        machine = rt.find('-isa', 'Stateflow.Machine', '-and', 'Name', modelName);
    catch
        return;
    end
    if isempty(machine)
        return;
    end

    try
        chartList = machine.find('-isa', 'Stateflow.Chart');
    catch
        return;
    end

    for i = 1:length(chartList)
        try
            info = localCaptureChart(chartList(i));
            charts(info.path) = info;
        catch
            % Skip unreadable chart.
        end
    end
end

function info = localCaptureChart(chart)
    info.path = char(string(chart.Path));
    info.name = char(string(chart.Name));
    info.actionLanguage = localGet(chart, 'ActionLanguage');
    info.sampleTime = localGet(chart, 'SampleTime');
    info.chartUpdate = localGet(chart, 'ChartUpdate');
    info.states = containers.Map('KeyType', 'char', 'ValueType', 'any');
    info.transitions = containers.Map('KeyType', 'char', 'ValueType', 'any');
    info.data = containers.Map('KeyType', 'char', 'ValueType', 'any');

    states = chart.find('-isa', 'Stateflow.State');
    for i = 1:length(states)
        st = states(i);
        key = localObjKey(info.path, 'state', st);
        s.name = char(string(st.Name));
        s.label = localNormalizeLabel(localGet(st, 'LabelString'));
        s.decomposition = localGet(st, 'Decomposition');
        s.ssid = localGet(st, 'SSIdNumber');
        info.states(key) = s;
    end

    transitions = chart.find('-isa', 'Stateflow.Transition');
    for i = 1:length(transitions)
        tr = transitions(i);
        key = localObjKey(info.path, 'trans', tr);
        t.label = localNormalizeLabel(localGet(tr, 'LabelString'));
        t.ssid = localGet(tr, 'SSIdNumber');
        [t.srcKey, t.srcName] = localEndpoint(info.path, tr.Source);
        [t.dstKey, t.dstName] = localEndpoint(info.path, tr.Destination);
        info.transitions(key) = t;
    end

    datas = chart.find('-isa', 'Stateflow.Data');
    for i = 1:length(datas)
        d = datas(i);
        key = localObjKey(info.path, 'data', d);
        di.name = char(string(d.Name));
        di.scope = localGet(d, 'Scope');
        di.dataType = localGet(d, 'DataType');
        di.ssid = localGet(d, 'SSIdNumber');
        info.data(key) = di;
    end
end

function key = localObjKey(chartPath, kind, obj)
    ssid = localGet(obj, 'SSIdNumber');
    if strlength(string(ssid)) == 0
        ssid = char(string(obj.Name));
    end
    key = sprintf('%s#%s:%s', chartPath, kind, char(string(ssid)));
end

function [key, name] = localEndpoint(chartPath, obj)
    key = '';
    name = '';
    if isempty(obj)
        return;
    end
    try
        name = char(string(obj.Name));
    catch
        name = '';
    end
    try
        if isa(obj, 'Stateflow.State')
            key = localObjKey(chartPath, 'state', obj);
        elseif isa(obj, 'Stateflow.Junction')
            key = localObjKey(chartPath, 'junction', obj);
        else
            key = localObjKey(chartPath, 'node', obj);
        end
    catch
        key = name;
    end
end

function v = localGet(obj, propName)
    try
        raw = obj.(propName);
        if isnumeric(raw) || islogical(raw)
            v = mat2str(raw);
        else
            v = char(string(raw));
        end
    catch
        v = '';
    end
end

function s = localNormalizeLabel(s)
    s = char(string(s));
    s = strrep(s, char(13), '');
    s = strrep(s, char(10), '\n');
end

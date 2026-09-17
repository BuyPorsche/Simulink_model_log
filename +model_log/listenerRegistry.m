function registry = listenerRegistry(action, key, value)
%LISTENERREGISTRY Manage Simulink listeners used by global Log.
%
% registry = listenerRegistry('get')
% listenerRegistry('set', registry)
% listenerRegistry('clear')

    persistent reg
    if isempty(reg)
        reg = struct('rootListener', [], 'modelListeners', containers.Map('KeyType', 'char', 'ValueType', 'any'));
    end

    if nargin < 1
        action = 'get';
    end

    switch action
        case 'get'
            registry = reg;
        case 'set'
            reg = key;
            registry = reg;
        case 'clear'
            reg = struct('rootListener', [], 'modelListeners', containers.Map('KeyType', 'char', 'ValueType', 'any'));
            registry = reg;
        case 'putModel'
            reg.modelListeners(key) = value;
            registry = reg;
        case 'removeModel'
            if isKey(reg.modelListeners, key)
                remove(reg.modelListeners, key);
            end
            registry = reg;
        otherwise
            error('model_log:listenerRegistry:UnknownAction', 'Unknown action: %s', action);
    end
end

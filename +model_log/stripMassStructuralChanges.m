function changes = stripMassStructuralChanges(changes)
%STRIPMASSSTRUCTURALCHANGES Remove whole-model add/remove noise from a diff.
%
% Keeps parameter / line / in-chart Stateflow edits so a first save after open
% can still record real changes without dumping every block as 模块新增.

    changes.blockAdded = {};
    changes.blockRemoved = {};
    changes.blockTypeChanged = struct('path', {}, 'oldType', {}, 'newType', {});
    if isfield(changes, 'chartAdded')
        changes.chartAdded = {};
    end
    if isfield(changes, 'chartRemoved')
        changes.chartRemoved = {};
    end
end

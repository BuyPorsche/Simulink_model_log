function tf = isFullModelResync(changes, newSnap)
%ISFULLMODELRESYNC True when every current block is reported as newly added.
%
% This includes the case where old baseline keys do not match (all removed +
% all added). Logging that would dump the whole model as 模块新增.

    tf = false;
    nNew = model_log.snapshotBlockCount(newSnap);
    if nNew == 0
        return;
    end
    nAdded = numel(changes.blockAdded);
    if nAdded < nNew
        return;
    end
    tf = true;
end

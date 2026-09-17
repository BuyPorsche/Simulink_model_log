function tf = isUsableSnapshot(snap)
%ISUSABLESNAPSHOT True when snapshot has a non-empty readable block collection.

    tf = false;
    if ~isstruct(snap)
        return;
    end
    tf = model_log.snapshotBlockCount(snap) > 0;
end

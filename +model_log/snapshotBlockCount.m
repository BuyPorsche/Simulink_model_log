function n = snapshotBlockCount(snap)
%SNAPSHOTBLOCKCOUNT Number of blocks recorded in a snapshot.

    n = 0;
    if ~isstruct(snap)
        return;
    end
    if isfield(snap, 'blocks') && isa(snap.blocks, 'containers.Map')
        n = snap.blocks.Count;
        return;
    end
    if isfield(snap, 'blockPaths')
        n = numel(snap.blockPaths);
    end
end

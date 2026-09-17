function snap = packSnapshot(snap)
%PACKSNAPSHOT Convert in-memory Map snapshot to MAT-friendly fields.

    if ~isstruct(snap)
        return;
    end
    if isfield(snap, 'blocks') && isa(snap.blocks, 'containers.Map')
        ks = snap.blocks.keys();
        vs = snap.blocks.values();
        snap.blockPaths = cellstr(string(ks(:)));
        snap.blockValues = vs(:);
        snap = rmfield(snap, 'blocks');
    end
    if isfield(snap, 'charts')
        packed = model_log.packChartMap(snap.charts);
        snap.chartPaths = packed.chartPaths;
        snap.chartValues = packed.chartValues;
        snap = rmfield(snap, 'charts');
    end
end

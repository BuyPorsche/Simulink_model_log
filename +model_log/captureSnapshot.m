function snap = captureSnapshot(modelName)
%CAPTURESNAPSHOT Walk a loaded Simulink model into a comparable snapshot.

    modelName = char(string(modelName));
    if ~bdIsLoaded(modelName)
        load_system(modelName);
    end

    wl = model_log.loadWhitelist();

    snap.modelName = modelName;
    snap.modelPath = char(string(get_param(modelName, 'FileName')));
    snap.capturedAt = model_log.timestampNow();
    snap.toolVersion = model_log.toolVersion();
    snap.blocks = containers.Map('KeyType', 'char', 'ValueType', 'any');
    snap.lines = struct('src', {}, 'dst', {});
    snap.charts = containers.Map('KeyType', 'char', 'ValueType', 'any');

    blocks = find_system(modelName, ...
        'LookUnderMasks', 'all', ...
        'FollowLinks', 'off', ...
        'Type', 'block');
    blocks = cellstr(string(blocks));

    lineKeys = containers.Map('KeyType', 'char', 'ValueType', 'logical');

    for i = 1:numel(blocks)
        blk = blocks{i};
        if strcmp(blk, modelName)
            continue;
        end
        blockType = char(string(get_param(blk, 'BlockType')));
        if strcmp(blockType, 'Annotation')
            continue;
        end

        info.path = blk;
        info.blockType = blockType;
        try
            info.maskType = char(string(get_param(blk, 'MaskType')));
        catch
            info.maskType = '';
        end
        info.name = char(string(get_param(blk, 'Name')));
        info.params = model_log.collectBlockParams(blk, wl);
        snap.blocks(blk) = info;

        try
            lh = get_param(blk, 'LineHandles');
        catch
            continue;
        end
        if ~isstruct(lh) || ~isfield(lh, 'Outport')
            continue;
        end
        outPorts = lh.Outport(:);
        for o = 1:numel(outPorts)
            lineH = outPorts(o);
            if ~(isnumeric(lineH) && isscalar(lineH) && lineH > 0 && ishandle(lineH))
                continue;
            end
            try
                srcBlock = char(string(get_param(lineH, 'SrcBlock')));
                srcPort = char(string(get_param(lineH, 'SrcPort')));
                dstBlocks = get_param(lineH, 'DstBlock');
                dstPorts = get_param(lineH, 'DstPort');
            catch
                continue;
            end
            srcKey = localEndpoint(modelName, srcBlock, srcPort);
            dstBlocks = cellstr(string(dstBlocks));
            dstPorts = cellstr(string(dstPorts));
            n = min(numel(dstBlocks), numel(dstPorts));
            for d = 1:n
                dstKey = localEndpoint(modelName, dstBlocks{d}, dstPorts{d});
                key = [srcKey '||' dstKey];
                if ~isKey(lineKeys, key)
                    lineKeys(key) = true;
                    snap.lines(end+1) = struct('src', srcKey, 'dst', dstKey);
                end
            end
        end
    end

    snap.charts = model_log.captureStateflow(modelName);
end

function key = localEndpoint(modelName, blockName, portNum)
    blockName = char(string(blockName));
    portNum = char(string(portNum));
    if startsWith(blockName, [modelName '/']) || strcmp(blockName, modelName)
        path = blockName;
    else
        path = [modelName '/' blockName];
    end
    key = [path '/' portNum];
end

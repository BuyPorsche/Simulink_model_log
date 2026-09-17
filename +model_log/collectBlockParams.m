function params = collectBlockParams(blockPath, whitelist)
%COLLECTBLOCKPARAMS Collect comparable dialog/mask/whitelist parameters for a block.
%
% Captures:
%   - All DialogParameters (typical module parameters users edit)
%   - Mask workspace parameters when present
%   - Extra names from whitelist.common / whitelist.byBlockType
% Ignores layout/UI noise listed in config ignore list (and built-in defaults).

    params = struct();
    blockPath = char(string(blockPath));

    ignore = localIgnoreSet(whitelist);
    names = {};

    try
        dp = get_param(blockPath, 'DialogParameters');
        if isstruct(dp)
            names = union(names, fieldnames(dp), 'stable');
        end
    catch
    end

    try
        maskNames = get_param(blockPath, 'MaskNames');
        if ~isempty(maskNames)
            names = union(names, cellstr(string(maskNames(:))), 'stable');
        end
    catch
    end

    if nargin >= 2 && ~isempty(whitelist)
        names = union(names, cellstr(string(whitelist.common(:))), 'stable');
        blockType = '';
        try
            blockType = char(string(get_param(blockPath, 'BlockType')));
        catch
        end
        if ~isempty(blockType) && isfield(whitelist, 'byBlockType') && ...
                isfield(whitelist.byBlockType, blockType)
            extra = cellstr(string(whitelist.byBlockType.(blockType)(:)));
            names = union(names, extra, 'stable');
        end
    end
    for i = 1:numel(names)
        pname = names{i};
        if isKey(ignore, pname)
            continue;
        end
        if ~isvarname(pname)
            % Struct field names must be valid MATLAB identifiers.
            continue;
        end
        try
            val = get_param(blockPath, pname);
            params.(pname) = model_log.paramValueToString(val);
        catch
        end
    end
end

function ignore = localIgnoreSet(whitelist)
    defaults = {
        'Position'
        'FontName'
        'FontSize'
        'FontWeight'
        'FontAngle'
        'ForegroundColor'
        'BackgroundColor'
        'NamePlacement'
        'DropShadow'
        'AttributesFormatString'
        'Selected'
        'Priority'
        'Tag'
        'UserData'
        'UserDataPersistent'
        'HiliteAncestors'
        'CopiedReferences'
        };
    if nargin >= 1 && isstruct(whitelist) && isfield(whitelist, 'ignore')
        defaults = [defaults(:); cellstr(string(whitelist.ignore(:)))];
    end
    ignore = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    d = unique(defaults);
    for i = 1:numel(d)
        ignore(d{i}) = true;
    end
end

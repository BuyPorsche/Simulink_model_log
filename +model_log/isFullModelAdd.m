function tf = isFullModelAdd(changes, newSnap)
%ISFULLMODELADD Backward-compatible alias of isFullModelResync.

    tf = model_log.isFullModelResync(changes, newSnap);
end

function ts = timestampNow()
%TIMESTAMPNOW Return a filesystem/log friendly local timestamp string.

    ts = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
end

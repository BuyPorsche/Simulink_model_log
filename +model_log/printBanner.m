function printBanner(varargin)
%PRINTBANNER Print model_log version / status line to the command window.
%
% model_log.printBanner()
% model_log.printBanner('Enabled')
% model_log.printBanner('Disabled')

    status = '';
    if nargin >= 1 && ~isempty(varargin{1})
        status = char(string(varargin{1}));
    end

    verStr = model_log.toolVersion();
    if isempty(status)
        fprintf('model_log %s\n', verStr);
    else
        fprintf('model_log %s | %s\n', verStr, status);
    end
end

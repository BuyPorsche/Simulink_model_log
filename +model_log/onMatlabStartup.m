function onMatlabStartup()
%ONMATLABSTARTUP Entry point for MATLAB startup.m — enable log and show version.
%
% Keep this call in startup.m; bump VERSION in the repo for future releases.
%
% Example in startup.m:
%   addpath('D:\98_Github\Model_change_log');
%   setupPath;
%   model_log.onMatlabStartup();

    setupPath();
    model_log.enable();
    fprintf('[startup.m] model_log %s loaded and ENABLED.\n', model_log.toolVersion());
end

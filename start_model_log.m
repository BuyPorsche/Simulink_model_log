%START_MODEL_LOG Enable model log for all model saves in this MATLAB session.
setupPath();
model_log.enable();
model_log.printBanner('ENABLED — logging all model saves in this session');
fprintf('Disable with: stop_model_log  or  model_log.disable()\n');

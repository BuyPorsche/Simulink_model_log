%demo_model_log Global enable, edit a model, show Log.
setupPath();
model_log.disable();

workDir = fullfile(tempdir, ['mcl_demo_' char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'))]);
mkdir(workDir);
modelName = 'MCL_Demo';
modelPath = fullfile(workDir, [modelName '.slx']);

if bdIsLoaded(modelName)
    close_system(modelName, 0);
end

new_system(modelName);
open_system(modelName);
add_block('simulink/Sources/In1', [modelName '/In1']);
add_block('simulink/Math Operations/Gain', [modelName '/G1']);
add_block('simulink/Sinks/Out1', [modelName '/Out1']);
set_param([modelName '/G1'], 'Gain', '1');
add_line(modelName, 'In1/1', 'G1/1');
add_line(modelName, 'G1/1', 'Out1/1');
save_system(modelName, modelPath);

model_log.enable();
set_param([modelName '/G1'], 'Gain', '2.5');
save_system(modelName);

[logPath, ~] = model_log.statePaths(modelPath);
fprintf('Log written to:\n%s\n\n', logPath);
if isfile(logPath)
    type(logPath);
end

fprintf('\nLogging is still ON for all models in this session.\n');
fprintf('Turn off with: stop_model_log  or  model_log.disable()\n');

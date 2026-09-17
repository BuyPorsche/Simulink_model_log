classdef tFullModelAddGuard < matlab.unittest.TestCase
    methods (Test)
        function emptyBaselineDoesNotLogAllBlocksAsAdded(testCase)
            setupPath();
            model_log.disable();
            workDir = tempname;
            mkdir(workDir);
            cleaner = onCleanup(@() localCleanup(workDir, 'MCL_FullAdd')); %#ok<NASGU>

            modelName = 'MCL_FullAdd';
            modelPath = fullfile(workDir, [modelName '.slx']);
            new_system(modelName);
            open_system(modelName);
            add_block('simulink/Math Operations/Gain', [modelName '/G1']);
            add_block('simulink/Sources/In1', [modelName '/In1']);
            add_block('simulink/Sinks/Out1', [modelName '/Out1']);
            save_system(modelName, modelPath);

            model_log.enable();
            [logPath, statePath] = model_log.statePaths(modelPath);

            % Corrupt baseline to empty packed snapshot (simulates bad first state).
            state = model_log.loadState(statePath);
            state.snapshot = struct( ...
                'modelName', modelName, ...
                'modelPath', modelPath, ...
                'capturedAt', '', ...
                'toolVersion', 'V1.0', ...
                'blockPaths', {{}}, ...
                'blockValues', {{}}, ...
                'lines', struct('src', {}, 'dst', {}));
            save(statePath, 'state', '-mat');

            set_param([modelName '/G1'], 'Gain', '9');
            save_system(modelName);

            % Must NOT create a log that lists every block as newly added.
            if isfile(logPath)
                txt = fileread(logPath);
                testCase.verifyFalse(contains(txt, '### Blocks Added'));
            end

            % Next real edit after healthy baseline should log parameter only.
            set_param([modelName '/G1'], 'Gain', '8');
            save_system(modelName);
            testCase.verifyTrue(isfile(logPath));
            txt = fileread(logPath);
            testCase.verifyTrue(contains(txt, '### Parameter Changes'));
            testCase.verifyTrue(contains(txt, 'Old: `9`') || contains(txt, 'New: `8`'));
            testCase.verifyFalse(contains(txt, '### Blocks Added'));
        end

        function pathMismatchResyncDoesNotDumpAllBlocksOnFirstLog(testCase)
            setupPath();
            model_log.disable();
            workDir = tempname;
            mkdir(workDir);
            cleaner = onCleanup(@() localCleanup(workDir, 'MCL_PathMis')); %#ok<NASGU>

            modelName = 'MCL_PathMis';
            modelPath = fullfile(workDir, [modelName '.slx']);
            new_system(modelName);
            open_system(modelName);
            add_block('simulink/Math Operations/Gain', [modelName '/G1']);
            add_block('simulink/Sources/In1', [modelName '/In1']);
            save_system(modelName, modelPath);

            model_log.enable();
            [logPath, statePath] = model_log.statePaths(modelPath);

            % Simulate baseline captured under a different path prefix.
            snap = model_log.captureSnapshot(modelName);
            snap = model_log.unpackSnapshot(snap);
            oldMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            ks = keys(snap.blocks);
            for i = 1:numel(ks)
                info = snap.blocks(ks{i});
                info.path = strrep(ks{i}, [modelName '/'], 'OtherModel/');
                oldMap(info.path) = info;
            end
            snap.blocks = oldMap;
            state = model_log.loadState(statePath);
            state.snapshot = snap;
            model_log.saveState(statePath, state);
            if isfile(logPath)
                delete(logPath);
            end

            set_param([modelName '/G1'], 'Gain', '3');
            save_system(modelName);

            % First save after path-mismatched baseline must not dump all blocks.
            if isfile(logPath)
                txt = fileread(logPath);
                testCase.verifyFalse(contains(txt, '### Blocks Added'));
                testCase.verifyFalse(contains(txt, '### Blocks Removed'));
            end

            % After resync baseline, a real parameter edit should log cleanly.
            set_param([modelName '/G1'], 'Gain', '4');
            save_system(modelName);
            testCase.verifyTrue(isfile(logPath));
            txt = fileread(logPath);
            testCase.verifyTrue(contains(txt, '### Parameter Changes'));
            testCase.verifyFalse(contains(txt, '### Blocks Added'));
        end
    end
end

function localCleanup(workDir, modelName)
    model_log.disable();
    if bdIsLoaded(modelName)
        close_system(modelName, 0);
    end
    if isfolder(workDir)
        rmdir(workDir, 's');
    end
end

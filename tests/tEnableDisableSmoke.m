classdef tEnableDisableSmoke < matlab.unittest.TestCase
    properties
        WorkDir
        ModelName = 'MCL_Smoke'
    end
    methods (TestMethodSetup)
        function createModel(testCase)
            setupPath();
            model_log.disable();
            testCase.WorkDir = tempname;
            mkdir(testCase.WorkDir);
            modelPath = fullfile(testCase.WorkDir, [testCase.ModelName '.slx']);
            new_system(testCase.ModelName);
            open_system(testCase.ModelName);
            add_block('simulink/Sources/In1', [testCase.ModelName '/In1']);
            add_block('simulink/Math Operations/Gain', [testCase.ModelName '/G1']);
            add_block('simulink/Sinks/Out1', [testCase.ModelName '/Out1']);
            set_param([testCase.ModelName '/G1'], 'Gain', '1');
            add_line(testCase.ModelName, 'In1/1', 'G1/1');
            add_line(testCase.ModelName, 'G1/1', 'Out1/1');
            save_system(testCase.ModelName, modelPath);
        end
    end
    methods (TestMethodTeardown)
        function cleanup(testCase)
            model_log.disable();
            names = {testCase.ModelName, 'MCL_Smoke2'};
            for i = 1:numel(names)
                if bdIsLoaded(names{i})
                    close_system(names{i}, 0);
                end
            end
            if isfolder(testCase.WorkDir)
                rmdir(testCase.WorkDir, 's');
            end
        end
    end
    methods (Test)
        function logsGainChangeOnSave(testCase)
            model_log.enable();
            testCase.verifyTrue(model_log.isEnabled());
            logPath = fullfile(testCase.WorkDir, [testCase.ModelName '_model_log.md']);

            set_param([testCase.ModelName '/G1'], 'Gain', '2.5');
            save_system(testCase.ModelName);
            testCase.verifyTrue(isfile(logPath));
            txt = fileread(logPath);
            testCase.verifyTrue(contains(txt, '### Parameter Changes'));
            testCase.verifyTrue(contains(txt, '2.5'));
            nSections = count(txt, '### Parameter Changes');

            model_log.disable();
            testCase.verifyFalse(model_log.isEnabled());
            set_param([testCase.ModelName '/G1'], 'Gain', '9');
            save_system(testCase.ModelName);
            txt2 = fileread(logPath);
            testCase.verifyEqual(count(txt2, '### Parameter Changes'), nSections);
        end

        function layoutOnlyDoesNotLog(testCase)
            model_log.enable();
            logPath = fullfile(testCase.WorkDir, [testCase.ModelName '_model_log.md']);
            if isfile(logPath)
                delete(logPath);
            end
            set_param([testCase.ModelName '/G1'], 'Position', [100 100 130 130]);
            save_system(testCase.ModelName);
            testCase.verifyFalse(isfile(logPath));
        end

        function logsAgainAfterCloseAndReopen(testCase)
            model_log.enable();
            modelPath = fullfile(testCase.WorkDir, [testCase.ModelName '.slx']);
            logPath = fullfile(testCase.WorkDir, [testCase.ModelName '_model_log.md']);

            set_param([testCase.ModelName '/G1'], 'Gain', '2');
            save_system(testCase.ModelName);
            testCase.verifyTrue(isfile(logPath));
            n1 = count(fileread(logPath), '### Parameter Changes');

            close_system(testCase.ModelName, 0);
            pause(0.25);
            open_system(modelPath);
            attached = false;
            for k = 1:50
                if localHasLive(testCase.ModelName)
                    attached = true;
                    break;
                end
                pause(0.05);
            end
            testCase.verifyTrue(attached, 'Listener was not re-attached after reopen');

            set_param([testCase.ModelName '/G1'], 'Gain', '5');
            save_system(testCase.ModelName);
            n2 = count(fileread(logPath), '### Parameter Changes');
            testCase.verifyGreaterThan(n2, n1);
        end

        function logsDialogParameterChanges(testCase)
            % Dialog parameters beyond the old hard-coded whitelist should log.
            model_log.enable();
            logPath = fullfile(testCase.WorkDir, [testCase.ModelName '_model_log.md']);
            if isfile(logPath)
                delete(logPath);
            end
            set_param([testCase.ModelName '/G1'], 'Multiplication', 'Matrix(K*u)');
            save_system(testCase.ModelName);
            testCase.verifyTrue(isfile(logPath));
            txt = fileread(logPath);
            testCase.verifyTrue(contains(txt, '### Parameter Changes'));
            testCase.verifyTrue(contains(txt, 'Multiplication'));
        end

        function openModelWithoutLogThenFirstSaveCreatesMd(testCase)
            % Open an existing model that has no *_model_log.md yet: baseline on open,
            % then first edit+save should create the markdown log.
            modelPath = fullfile(testCase.WorkDir, [testCase.ModelName '.slx']);
            logPath = fullfile(testCase.WorkDir, [testCase.ModelName '_model_log.md']);
            statePath = fullfile(testCase.WorkDir, ['.' testCase.ModelName '_model_log_.mat']);

            model_log.disable();
            if isfile(logPath), delete(logPath); end
            if isfile(statePath), delete(statePath); end
            close_system(testCase.ModelName, 0);

            model_log.enable();
            open_system(modelPath);
            for k = 1:50
                if isfile(statePath)
                    break;
                end
                pause(0.05);
            end
            testCase.verifyTrue(isfile(statePath), 'Baseline state was not created on open');
            testCase.verifyFalse(isfile(logPath), 'Opening must not create md by itself');

            set_param([testCase.ModelName '/G1'], 'Gain', '6.5');
            save_system(testCase.ModelName);
            testCase.verifyTrue(isfile(logPath), 'First save after open should create md');
            txt = fileread(logPath);
            testCase.verifyTrue(contains(txt, '### Parameter Changes'));
            testCase.verifyTrue(contains(txt, '6.5'));
            testCase.verifyFalse(contains(txt, '### Blocks Added'));
        end

        function appliesToNewlyOpenedModel(testCase)
            model_log.enable();
            otherName = ['MCL_Smoke2_' char(datetime('now', 'Format', 'HHmmssSSS'))];
            otherPath = fullfile(testCase.WorkDir, [otherName '.slx']);
            new_system(otherName);
            open_system(otherName);
            % Wait for deferred PostSave listener attachment (timer StartDelay 0).
            attached = false;
            for k = 1:50
                reg = model_log.listenerRegistry('get');
                if isKey(reg.modelListeners, otherName)
                    attached = true;
                    break;
                end
                pause(0.02);
            end
            testCase.verifyTrue(attached);
            add_block('simulink/Math Operations/Gain', [otherName '/G1']);
            set_param([otherName '/G1'], 'Gain', '1');
            save_system(otherName, otherPath);
            % First save establishes baseline; next save with change should log.
            set_param([otherName '/G1'], 'Gain', '3');
            save_system(otherName);
            logPath = fullfile(testCase.WorkDir, [otherName '_model_log.md']);
            testCase.verifyTrue(isfile(logPath));
            txt = fileread(logPath);
            testCase.verifyTrue(contains(txt, '3'));
            close_system(otherName, 0);
        end
    end
end

function tf = localHasLive(modelName)
    tf = false;
    reg = model_log.listenerRegistry('get');
    if ~isKey(reg.modelListeners, modelName)
        return;
    end
    entry = reg.modelListeners(modelName);
    if isstruct(entry) && isfield(entry, 'postSave')
        L = entry.postSave;
    else
        L = entry;
    end
    if isempty(L) || ~isvalid(L)
        return;
    end
    try
        src = L.Source{1};
        tf = isvalid(src) && strcmp(src.Name, modelName);
    catch
        tf = false;
    end
end

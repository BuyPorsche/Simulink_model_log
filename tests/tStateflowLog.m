classdef tStateflowLog < matlab.unittest.TestCase
    properties
        WorkDir
        ModelName = 'MCL_SF_Log'
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
            add_block('sflib/Chart', [testCase.ModelName '/Chart']);

            rt = sfroot;
            machine = rt.find('-isa', 'Stateflow.Machine', '-and', 'Name', testCase.ModelName);
            chart = machine.find('-isa', 'Stateflow.Chart');
            s1 = Stateflow.State(chart);
            s1.LabelString = ['Off' newline 'entry: y=0;'];
            s2 = Stateflow.State(chart);
            s2.LabelString = ['On' newline 'entry: y=1;'];
            tr = Stateflow.Transition(chart);
            tr.Source = s1;
            tr.Destination = s2;
            tr.LabelString = '[u>0]';

            save_system(testCase.ModelName, modelPath);
        end
    end
    methods (TestMethodTeardown)
        function cleanup(testCase)
            model_log.disable();
            if bdIsLoaded(testCase.ModelName)
                close_system(testCase.ModelName, 0);
            end
            if isfolder(testCase.WorkDir)
                rmdir(testCase.WorkDir, 's');
            end
        end
    end
    methods (Test)
        function logsStateLabelChange(testCase)
            model_log.enable();
            logPath = fullfile(testCase.WorkDir, [testCase.ModelName '_model_log.md']);

            rt = sfroot;
            machine = rt.find('-isa', 'Stateflow.Machine', '-and', 'Name', testCase.ModelName);
            chart = machine.find('-isa', 'Stateflow.Chart');
            states = chart.find('-isa', 'Stateflow.State');
            % Change label of first state
            states(1).LabelString = ['Off' newline 'entry: y=2;'];

            save_system(testCase.ModelName);
            testCase.verifyTrue(isfile(logPath));
            txt = fileread(logPath);
            testCase.verifyTrue(contains(txt, '### Stateflow Changes'));
            testCase.verifyTrue(contains(txt, 'State Changed') || contains(txt, 'Label'));
            testCase.verifyTrue(contains(txt, 'y=2') || contains(txt, 'New:'));
        end

        function logsNewStateAndTransition(testCase)
            model_log.enable();
            logPath = fullfile(testCase.WorkDir, [testCase.ModelName '_model_log.md']);
            if isfile(logPath)
                delete(logPath);
            end

            rt = sfroot;
            machine = rt.find('-isa', 'Stateflow.Machine', '-and', 'Name', testCase.ModelName);
            chart = machine.find('-isa', 'Stateflow.Chart');
            sFault = Stateflow.State(chart);
            sFault.LabelString = 'Fault';
            states = chart.find('-isa', 'Stateflow.State');
            onState = [];
            for i = 1:length(states)
                if contains(string(states(i).Name), 'On') || contains(string(states(i).LabelString), 'On')
                    onState = states(i);
                    break;
                end
            end
            testCase.assumeFalse(isempty(onState));
            tr = Stateflow.Transition(chart);
            tr.Source = onState;
            tr.Destination = sFault;
            tr.LabelString = '[error]';

            save_system(testCase.ModelName);
            testCase.verifyTrue(isfile(logPath));
            txt = fileread(logPath);
            testCase.verifyTrue(contains(txt, '### Stateflow Changes'));
            testCase.verifyTrue(contains(txt, 'State Added') || contains(txt, 'Fault'));
            testCase.verifyTrue(contains(txt, 'Transition Added') || contains(txt, 'error'));
        end
    end
end

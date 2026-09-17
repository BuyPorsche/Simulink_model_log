classdef tStatePaths < matlab.unittest.TestCase
    methods (Test)
        function derivesSidecarNames(testCase)
            setupPath();
            slx = fullfile('C:', 'models', 'Plant.slx');
            [logPath, statePath] = model_log.statePaths(slx);
            testCase.verifyEqual(logPath, fullfile('C:', 'models', 'Plant_model_log.md'));
            testCase.verifyEqual(statePath, fullfile('C:', 'models', '.Plant_model_log_.mat'));
        end
    end
end

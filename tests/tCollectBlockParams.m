classdef tCollectBlockParams < matlab.unittest.TestCase
    methods (Test)
        function capturesDialogParamsForGain(testCase)
            setupPath();
            modelName = 'MCL_ParamCap';
            if bdIsLoaded(modelName)
                close_system(modelName, 0);
            end
            new_system(modelName);
            open_system(modelName);
            cleaner = onCleanup(@() close_system(modelName, 0)); %#ok<NASGU>
            add_block('simulink/Math Operations/Gain', [modelName '/G1']);
            set_param([modelName '/G1'], 'Gain', '7');
            wl = model_log.loadWhitelist();
            params = model_log.collectBlockParams([modelName '/G1'], wl);
            testCase.verifyTrue(isfield(params, 'Gain'));
            testCase.verifyEqual(params.Gain, '7');
            testCase.verifyTrue(isfield(params, 'Multiplication') || isfield(params, 'SampleTime'));
            testCase.verifyFalse(isfield(params, 'Position'));
        end
    end
end

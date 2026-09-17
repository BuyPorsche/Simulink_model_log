classdef tLoadWhitelist < matlab.unittest.TestCase
    methods (Test)
        function loadsGainParams(testCase)
            setupPath();
            wl = model_log.loadWhitelist();
            testCase.verifyTrue(any(strcmp(wl.common, 'SampleTime')));
            testCase.verifyTrue(any(strcmp(wl.byBlockType.Gain, 'Gain')));
        end
    end
end

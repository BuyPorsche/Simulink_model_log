classdef tDiffSnapshots < matlab.unittest.TestCase
    methods (Test)
        function detectsBlockAddRemove(testCase)
            setupPath();
            oldS = localSnap();
            oldS.blocks('A/G1') = localBlock('A/G1', 'Gain');
            newS = localSnap();
            newS.blocks('A/G2') = localBlock('A/G2', 'Gain');
            c = model_log.diffSnapshots(oldS, newS);
            testCase.verifyEqual(c.blockRemoved{1}.path, 'A/G1');
            testCase.verifyEqual(c.blockAdded{1}.path, 'A/G2');
            testCase.verifyFalse(model_log.isEmptyChanges(c));
        end

        function detectsParamChange(testCase)
            setupPath();
            oldS = localSnap();
            b = localBlock('A/G1', 'Gain');
            b.params.Gain = '1';
            oldS.blocks('A/G1') = b;
            newS = localSnap();
            b2 = localBlock('A/G1', 'Gain');
            b2.params.Gain = '2';
            newS.blocks('A/G1') = b2;
            c = model_log.diffSnapshots(oldS, newS);
            testCase.verifyEqual(c.paramChanged(1).param, 'Gain');
            testCase.verifyEqual(c.paramChanged(1).oldValue, '1');
            testCase.verifyEqual(c.paramChanged(1).newValue, '2');
        end

        function detectsLineChanges(testCase)
            setupPath();
            oldS = localSnap();
            oldS.lines = struct('src', {'In1/1'}, 'dst', {'G1/1'});
            newS = localSnap();
            newS.lines = struct('src', {'In1/1'}, 'dst', {'G2/1'});
            c = model_log.diffSnapshots(oldS, newS);
            testCase.verifyEqual(c.lineRemoved(1).dst, 'G1/1');
            testCase.verifyEqual(c.lineAdded(1).dst, 'G2/1');
        end

        function emptyWhenIdentical(testCase)
            setupPath();
            s = localSnap();
            s.blocks('A/G1') = localBlock('A/G1', 'Gain');
            c = model_log.diffSnapshots(s, s);
            testCase.verifyTrue(model_log.isEmptyChanges(c));
        end
    end
end

function s = localSnap()
    s.modelName = 'M';
    s.modelPath = '';
    s.capturedAt = '';
    s.toolVersion = '0.1.0';
    s.blocks = containers.Map('KeyType', 'char', 'ValueType', 'any');
    s.lines = struct('src', {}, 'dst', {});
end

function b = localBlock(path, typ)
    b.path = path;
    b.blockType = typ;
    b.maskType = '';
    b.name = '';
    b.params = struct();
end

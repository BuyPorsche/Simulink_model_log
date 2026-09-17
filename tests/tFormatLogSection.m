classdef tFormatLogSection < matlab.unittest.TestCase
    methods (Test)
        function rendersParamTable(testCase)
            setupPath();
            meta.timestamp = '2026-07-22 11:34:05';
            meta.user = 'ELLX1JB';
            meta.modelName = 'MyModel';
            meta.version = 7;
            c = emptyChanges();
            c.paramChanged = struct( ...
                'path', {'Controller/Gain1'}, ...
                'param', {'Gain'}, ...
                'oldValue', {'1'}, ...
                'newValue', {'2.5'});
            md = model_log.formatLogSection(meta, c);
            testCase.verifyTrue(contains(md, '## 2026-07-22 11:34:05 | Version: 7 | User: ELLX1JB | Model: MyModel'));
            testCase.verifyTrue(contains(md, '### Parameter Changes'));
            testCase.verifyTrue(contains(md, '- Block: `Controller/Gain1`'));
            testCase.verifyTrue(contains(md, '- Param: `Gain`'));
            testCase.verifyTrue(contains(md, '- Old: `1`'));
            testCase.verifyTrue(contains(md, '- New: `2.5`'));
            testCase.verifyFalse(contains(md, '### Blocks Added'));
        end

        function headerRowsSurroundedByHashRule(testCase)
            setupPath();
            meta.timestamp = '2026-07-22 11:34:05';
            meta.user = 'ELLX1JB';
            meta.modelName = 'MyModel';
            meta.version = 1;
            c = emptyChanges();
            c.blockAdded = {struct('path', 'A/B', 'blockType', 'Gain')};
            md = model_log.formatLogSection(meta, c);
            rule = repmat('#', 1, 60);
            linesArr = strsplit(md, newline);
            idx = find(startsWith(linesArr, '## 2026-07-22 11:34:05 | Version: 1'), 1);
            testCase.verifyNotEmpty(idx);
            % 节头前后各有一排 # 分隔线
            testCase.verifyEqual(linesArr{idx-1}, rule);
            testCase.verifyEqual(linesArr{idx+1}, rule);
        end

        function versionDefaultsToOneForLegacyMeta(testCase)
            setupPath();
            meta.timestamp = '2026-07-22 11:34:05';
            meta.user = 'ELLX1JB';
            meta.modelName = 'MyModel';  % no version field (legacy callers)
            c = emptyChanges();
            c.blockAdded = {struct('path', 'A/B', 'blockType', 'Gain')};
            md = model_log.formatLogSection(meta, c);
            testCase.verifyTrue(contains(md, 'Version: 1'));
        end

        function appendCreatesFileAndSkipsEmpty(testCase)
            setupPath();
            tmp = tempname;
            mkdir(tmp);
            cleaner = onCleanup(@() localRmdir(tmp)); %#ok<NASGU>
            logPath = fullfile(tmp, 'X_model_log.md');
            meta.timestamp = '2026-07-22 12:00:00';
            meta.user = 'u';
            meta.modelName = 'X';
            meta.version = 1;
            model_log.appendLog(logPath, meta, emptyChanges());
            testCase.verifyFalse(isfile(logPath));
            c = emptyChanges();
            c.blockAdded = {struct('path', 'A/B', 'blockType', 'Gain')};
            model_log.appendLog(logPath, meta, c);
            testCase.verifyTrue(isfile(logPath));
            txt = fileread(logPath);
            testCase.verifyTrue(contains(txt, '# Simulink Model Log: X'));
            testCase.verifyTrue(contains(txt, '### Blocks Added'));
        end
    end
end

function c = emptyChanges()
    c.blockAdded = {};
    c.blockRemoved = {};
    c.blockTypeChanged = struct('path', {}, 'oldType', {}, 'newType', {});
    c.paramChanged = struct('path', {}, 'param', {}, 'oldValue', {}, 'newValue', {});
    c.lineAdded = struct('src', {}, 'dst', {});
    c.lineRemoved = struct('src', {}, 'dst', {});
end

function localRmdir(tmp)
    if isfolder(tmp)
        rmdir(tmp, 's');
    end
end

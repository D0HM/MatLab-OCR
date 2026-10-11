function results = run_tests()
% RUN_TESTS Core evaluation tests do not require OCR or an installed OCR model.
root=fileparts(mfilename('fullpath')); addpath(root,fullfile(root,'src'));
results=runtests(fullfile(root,'tests'));
disp(results); assert(all([results.Passed]),'Some MATLAB tests failed.');
end

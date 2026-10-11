function outDir = start_demo()
% START_DEMO Run bundled synthetic test images; no downloads required.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
cfg = project_config('demo');
outDir = run_experiment(cfg);
fprintf('\nDemo only: use independent REAL photos for your final report.\n');
end

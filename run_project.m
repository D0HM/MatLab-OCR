function outDir = run_project(split)
% RUN_PROJECT Run all seven original Challenge02 images.
if nargin < 1, split = 'all'; end
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
cfg = project_config('provided');
cfg.Split = string(split);
outDir = run_experiment(cfg);
end

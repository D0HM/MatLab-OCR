function sweepDir = run_frequency_sweep(cutoffs)
% RUN_FREQUENCY_SWEEP Compare frequency cutoffs on the same seven images.
% This is a case-study sweep, not held-out tuning or automatic model selection.
if nargin<1, cutoffs=[0.035 0.05 0.065 0.09]; end
root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'src'));
assert(all(isfinite(cutoffs) & cutoffs>0 & cutoffs<=0.5),'Use positive cutoffs <=0.5.');
cfg=project_config('provided'); cfg.Methods=["F1","F2"];
if ~isfolder(cfg.OutputRoot), mkdir(cfg.OutputRoot); end
[~,token]=fileparts(tempname); sweepDir=fullfile(cfg.OutputRoot,['sweep_' token]);
mkdir(sweepDir); combined=table();
for cutoff=cutoffs(:)'
    cfg.GaussianCutoff=cutoff;
    outDir=run_experiment(cfg);
    s=readtable(fullfile(outDir,'summary.csv'),'TextType','string');
    s=addvars(s,repmat(cutoff,height(s),1),repmat(string(outDir),height(s),1), ...
        'Before',1,'NewVariableNames',{'GaussianCutoff','RunDirectory'});
    if isempty(combined), combined=s; else, combined=[combined;s]; end %#ok<AGROW>
    writetable(combined,fullfile(sweepDir,'sweep_summary.csv'));
end
write_text(fullfile(sweepDir,'README.txt'), ...
    ['Frequency cutoff comparison on the same provided images. ' ...
    'Confidence is not accuracy. ScoredImages=0 means labels remain draft. ' ...
    'Changing parameters using these images does not create held-out results.']);
fprintf('Frequency sweep completed: %s\n',sweepDir);
end

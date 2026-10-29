function out = merge_results(resultsDir, varargin)
% MERGE_RESULTS Merge every method/detector in a results folder into one final prediction per image.
% USAGE (no OCR rerun, seconds):
%   merge_results('results\20261012_232630_...')                        % defaults below
%   merge_results(dirPath,'MinConf',0.7,'MinSupport',2,'MinLen',1,'IoU',0.5,'Methods',["M0","F3"])
% Writes <resultsDir>\final_prediction.csv (ImageID,x,y,width,height,text,confidence,support).
% MinConf: keep any read with confidence >= this; MinSupport: or seen by this many method/detector pairs.
% Raise MinConf/MinLen to cut false positives; lower them to cut misses. Base MATLAB only.
o = struct('MinConf',0.7,'MinSupport',2,'MinLen',1,'IoU',0.5,'Methods',[]);
for k = 1:2:numel(varargin), o.(varargin{k}) = varargin{k+1}; end
f = fullfile(resultsDir,'ocr_results.csv');
opts = detectImportOptions(f); opts = setvartype(opts,'text','string'); R = readtable(f,opts);
R = R(~ismissing(R.text),:);
if ~isempty(o.Methods), R = R(ismember(string(R.Method),string(o.Methods)),:); end
key = cellstr(string(R.Method) + "/" + string(R.Detector));
ids = unique(string(R.ImageID),'stable'); out = table();
for i = 1:numel(ids)
    m = string(R.ImageID) == ids(i);
    B = [R.x(m) R.y(m) R.width(m) R.height(m)]; T = cellstr(R.text(m)); C = R.confidence(m); K = key(m);
    [keep, sup] = merge_predictions_core(B, T, C, K, o.MinSupport, o.MinConf, o.MinLen, o.IoU);
    out = [out; table(repmat(ids(i),numel(keep),1), B(keep,1), B(keep,2), B(keep,3), B(keep,4), string(T(keep)), C(keep), sup, ...
        'VariableNames',{'ImageID','x','y','width','height','text','confidence','support'})]; %#ok<AGROW>
end
writetable(out, fullfile(resultsDir,'final_prediction.csv'));
fprintf('final_prediction.csv: %d words over %d images\n', height(out), numel(ids));
end

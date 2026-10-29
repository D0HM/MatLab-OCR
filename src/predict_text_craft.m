function [pred, candidates] = predict_text_craft(P, cfg, Idet)
% PREDICT_TEXT_CRAFT Detector "craft": the pretrained CRAFT text detector finds boxes on the ORIGINAL image
% (Idet; frequency filtering lowers detection recall), then each box is cropped from P (the F1/F2/F3 image),
% straightened by the FFT angle estimate and read by ocr (ocr_deskew_core).
% cfg.CraftDetectOnOriginal (default true) = false detects on P instead, for an ablation in the report.
% REQUIRES: Computer Vision Toolbox, Deep Learning Toolbox and the add-on "Computer Vision Toolbox
% Model for Text Detection" (Add-On Explorer). Optional cfg: CraftCharThreshold(0.3) CraftMaxBoxes(60)
% ROIPadding(6) plus the ocr_deskew_core options. Use: cfg.Detectors = "craft".
if exist('detectTextCRAFT','file') ~= 2
    error('SceneText:Craft','detectTextCRAFT not found. Install "Computer Vision Toolbox Model for Text Detection" (Add-On Explorer) and Deep Learning Toolbox.');
end
pred = table(zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1),strings(0,1),zeros(0,1), ...
    'VariableNames',{'x','y','width','height','text','confidence'});
if nargin < 3 || isempty(Idet) || (isfield(cfg,'CraftDetectOnOriginal') && ~cfg.CraftDetectOnOriginal), Idet = P; end
I = Idet; if ndims(I) == 2, I = repmat(I, [1 1 3]); end
thr = 0.3; if isfield(cfg,'CraftCharThreshold'), thr = cfg.CraftCharThreshold; end
candidates = double(detectTextCRAFT(I, 'CharacterThreshold', thr));
if size(candidates,2) ~= 4, candidates = zeros(0,4); end
maxBoxes = 60; if isfield(cfg,'CraftMaxBoxes'), maxBoxes = cfg.CraftMaxBoxes; end
[~, ord] = sort(candidates(:,3).*candidates(:,4), 'descend'); candidates = candidates(ord(1:min(end,maxBoxes)),:);
padPx = 6; if isfield(cfg,'ROIPadding'), padPx = cfg.ROIPadding; end
[H, W, ~] = size(P);
for k = 1:size(candidates,1)
    b = candidates(k,:);
    x1 = max(1,floor(b(1)-padPx)); y1 = max(1,floor(b(2)-padPx)); x2 = min(W,ceil(b(1)+b(3)-1+padPx)); y2 = min(H,ceil(b(2)+b(4)-1+padPx));
    if min(y2-y1+1, x2-x1+1) < 8, continue; end
    [bb, ww, cc] = ocr_deskew_core(P(y1:y2,x1:x2,:), cfg, @(img,layout) ocr_compat(img, layout, cfg));
    if isempty(ww), continue; end
    bb(:,1) = bb(:,1)+x1-1; bb(:,2) = bb(:,2)+y1-1;
    pred = [pred; table(bb(:,1),bb(:,2),bb(:,3),bb(:,4),string(ww(:)),cc(:),'VariableNames',pred.Properties.VariableNames)]; %#ok<AGROW>
end
if ~isempty(pred), pred = pred(reading_order(pred{:,1:4}),:); end
end

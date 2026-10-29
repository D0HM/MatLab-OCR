function [boxes, words, conf, source] = ocr_crops_core(I, cand, cfg, ocrFcn)
% OCR_CROPS_CORE Method F4: per-box frequency-domain OCR. Every detector box is cropped from the
% ORIGINAL image, scaled so its text is ~F4TargetHeights px tall, run through the F3 FFT variants
% (channel x pipeline x lowpass cutoff x scale x layout) and voted on (ocr_variants_core).
%   cand: [x y w h] boxes in image pixels; ocrFcn(img,layout) -> OCR struct.
% Optional cfg: F4MaxCrops(12) F4TargetHeights([32 48 72]) F4Channels({'gray','sat'}) F4Pipelines({'lowpass'})
%   F4Sigmas([0.04 0.09]) F4Border(10) F4Layouts({'word','block'}) F4MinVotes(2) F4MinConfidence(0.3)
boxes = zeros(0,4); words = {}; conf = zeros(0,1); source = {};
if isempty(cand), return; end
maxCrops = getf(cfg,'F4MaxCrops',12); targets = getf(cfg,'F4TargetHeights',[32 48 72]);
pad = getf(cfg,'ROIPadding',24);
[~, ord] = sort(cand(:,3).*cand(:,4), 'descend'); cand = cand(ord(1:min(end,maxCrops)),:);
c = cfg; c.F3Channels = getf(cfg,'F4Channels',{'gray','sat'}); c.F3Pipelines = getf(cfg,'F4Pipelines',{'lowpass'});
c.F3Sigmas = getf(cfg,'F4Sigmas',[0.04 0.09]); c.F3Border = getf(cfg,'F4Border',10);
c.F3Layouts = getf(cfg,'F4Layouts',{'word','block'}); c.F3MinVotes = getf(cfg,'F4MinVotes',2);
c.F3Notch = false; c.F3Invert = false; c.F3MinChars = max(getf(cfg,'F3MinChars',2),2);
c.F3MinConfidence = getf(cfg,'F4MinConfidence',0.3);
[H, W, ~] = size(I);
for k = 1:size(cand,1)
    b = cand(k,:);
    x1 = max(1,floor(b(1)-pad)); y1 = max(1,floor(b(2)-pad));
    x2 = min(W,ceil(b(1)+b(3)-1+pad)); y2 = min(H,ceil(b(2)+b(4)-1+pad));
    if min(y2-y1+1, x2-x1+1) < 16, continue; end
    c.F3Scales = unique(round(min(2, max(0.04, targets/max(b(4),1)))*1000)/1000);
    [bb, ww, cc, ss] = ocr_variants_core(I(y1:y2,x1:x2,:), c, ocrFcn);
    if isempty(ww), continue; end
    bb(:,1) = bb(:,1)+x1-1; bb(:,2) = bb(:,2)+y1-1;
    boxes = [boxes; bb]; words = [words; ww]; conf = [conf; cc]; source = [source; ss]; %#ok<AGROW>
end
% Merge duplicates across overlapping crops (confidence x sqrt(length) ranking).
if numel(words) > 1
    len = cellfun(@numel, words); [~, ord] = sort(conf(:).*sqrt(min(len(:),8)), 'descend');
    keep = []; contain = getf(cfg,'ResultContainment',0.8); iouT = getf(cfg,'F3NMSIoU',0.3);
    for i = ord(:)'
        ok = true;
        for j = keep
            if box_iou(boxes(i,:), boxes(j,:)) >= iouT || contained(boxes(i,:), boxes(j,:)) >= contain, ok = false; break; end
        end
        if ok, keep(end+1) = i; end %#ok<AGROW>
    end
    boxes = boxes(keep,:); words = words(keep); conf = conf(keep); source = source(keep);
end
end

function v = getf(cfg, name, fallback)
if isfield(cfg,name), v = cfg.(name); else, v = fallback; end
end

function v = box_iou(a, b)
x1 = max(a(1),b(1)); y1 = max(a(2),b(2)); x2 = min(a(1)+a(3),b(1)+b(3)); y2 = min(a(2)+a(4),b(2)+b(4));
i = max(0,x2-x1)*max(0,y2-y1); v = i/(a(3)*a(4)+b(3)*b(4)-i);
end

function v = contained(a, b)
x1 = max(a(1),b(1)); y1 = max(a(2),b(2)); x2 = min(a(1)+a(3),b(1)+b(3)); y2 = min(a(2)+a(4),b(2)+b(4));
v = max(0,x2-x1)*max(0,y2-y1)/max(min(a(3)*a(4),b(3)*b(4)),eps);
end

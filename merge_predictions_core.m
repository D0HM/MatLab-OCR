function [keep, support] = merge_predictions_core(B, T, C, K, minSup, minConf, minLen, iouT)
% MERGE_PREDICTIONS_CORE Merge OCR reads of ONE image from several methods/detectors.
%   B Nx4 [x y w h], T cellstr text, C Nx1 confidence, K cellstr source key (e.g. 'F3/ocr').
% 1) non-maximum suppression, ranked by confidence*sqrt(min(len,8))
% 2) keep a read if its text was seen by >= minSup different sources (IoU>=0.3, same text, case-insens.)
%    OR its confidence >= minConf; drop words shorter than minLen.
% Returns keep (row indices into the inputs) and support (number of agreeing sources per kept row).
n = numel(T); keep = zeros(0,1); support = zeros(0,1);
if n == 0, return; end
C(~isfinite(C)) = 0; len = cellfun(@numel, T(:));
[~, ord] = sort(C(:).*sqrt(min(len,8)), 'descend'); kept = zeros(0,1);
for i = ord(:)'
    if any(arrayfun(@(j) iou(B(i,:),B(j,:)) >= iouT, kept)), continue; end
    kept(end+1) = i; %#ok<AGROW>
    same = find(strcmpi(T, T{i}) & arrayfun(@(j) iou(B(i,:),B(j,:)) >= 0.3, (1:n)'));
    sup = numel(unique(K(same)));
    if (sup >= minSup || C(i) >= minConf) && len(i) >= minLen
        keep(end+1,1) = i; support(end+1,1) = sup; %#ok<AGROW>
    end
end
end

function v = iou(a, b)
x1 = max(a(1),b(1)); y1 = max(a(2),b(2)); x2 = min(a(1)+a(3),b(1)+b(3)); y2 = min(a(2)+a(4),b(2)+b(4));
i = max(0,x2-x1)*max(0,y2-y1); v = i/(a(3)*a(4)+b(3)*b(4)-i);
end

function [boxes, words, conf] = ocr_deskew_core(crop, cfg, ocrFcn)
% OCR_DESKEW_CORE OCR one text box after FFT-based straightening.
%   1) estimate_text_angle (FFT spectrum) 2) rotate to horizontal (if the tilt is DeskewMinAngle..DeskewMaxAngle)
%   3) OCR the straightened crop in each layout, dark-on-light and (optionally) inverted
%   4) map word boxes back to the crop's own coordinates 5) merge duplicates by confidence.
% ocrFcn(img,layout) -> struct Words/WordBoundingBoxes/WordConfidences. Optional cfg fields:
%   DeskewMinAngle(3) DeskewMaxAngle(35) CraftLayouts({'word','block'}) CraftTryInvert(true) MinConfidence(0)
boxes = zeros(0,4); words = {}; conf = zeros(0,1);
G = double(crop); if ndims(G) == 3, G = 0.2989*G(:,:,1)+0.5870*G(:,:,2)+0.1140*G(:,:,3); end
G = uint8(min(255, max(0, G)));
minA = getf(cfg,'DeskewMinAngle',3); maxA = getf(cfg,'DeskewMaxAngle',35);
layouts = getf(cfg,'CraftLayouts',{'word','block'}); if ischar(layouts) || isstring(layouts), layouts = cellstr(layouts); end
tryInv = getf(cfg,'CraftTryInvert',true); minConf = getf(cfg,'MinConfidence',0);
est = estimate_text_angle(G);
angles = 0; if abs(est) >= minA && abs(est) <= maxA, angles(end+1) = -est; end
border = [G(1,:), G(end,:), G(:,1)', G(:,end)']; fill = double(median(border)); bw = 10;
for ang = angles
    if ang == 0
        R = G; M = [];
    else
        [R, M] = rotate_image(G, ang, fill);
    end
    for inv = [false tryInv]
        img = R; f = fill; if inv, img = 255-R; f = 255-fill; end
        [h, w] = size(img);
        img = [f*ones(bw, w+2*bw); f*ones(h, bw), double(img), f*ones(h, bw); f*ones(bw, w+2*bw)];
        img = uint8(img);
        for ell = 1:numel(layouts)
            r = ocrFcn(img, layouts{ell});
            ww = cellstr(r.Words(:)); bb = double(r.WordBoundingBoxes); cc = double(r.WordConfidences(:));
            for j = 1:numel(ww)
                t = regexprep(strtrim(ww{j}), '^[^A-Za-z0-9]+|[^A-Za-z0-9]+$', '');
                if isempty(regexp(t,'^[A-Za-z0-9]+$','once')) || ~all(isfinite(bb(j,:))) || bb(j,3) <= 0 || bb(j,4) <= 0, continue; end
                if minConf > 0 && ~(isfinite(cc(j)) && cc(j) >= minConf), continue; end
                b = bb(j,:); b(1:2) = b(1:2) - bw;
                if ~isempty(M), b = rotate_points_back(b, M); end
                boxes(end+1,:) = b; words{end+1,1} = t; conf(end+1,1) = cc(j); %#ok<AGROW>
            end
        end
    end
end
% merge duplicates
if numel(words) > 1
    len = cellfun(@numel, words); sc = conf; sc(~isfinite(sc)) = 0; [~, ord] = sort(sc(:).*sqrt(min(len(:),8)), 'descend'); keep = [];
    for i = ord(:)'
        if ~any(arrayfun(@(j) iou(boxes(i,:),boxes(j,:)) >= 0.5 || contained(boxes(i,:),boxes(j,:)) >= 0.8, keep)), keep(end+1) = i; end %#ok<AGROW>
    end
    boxes = boxes(keep,:); words = words(keep); conf = conf(keep);
end
end

function v = getf(cfg, name, fallback)
if isfield(cfg,name), v = cfg.(name); else, v = fallback; end
end
function v = iou(a, b)
x1=max(a(1),b(1)); y1=max(a(2),b(2)); x2=min(a(1)+a(3),b(1)+b(3)); y2=min(a(2)+a(4),b(2)+b(4));
i=max(0,x2-x1)*max(0,y2-y1); v=i/(a(3)*a(4)+b(3)*b(4)-i);
end
function v = contained(a, b)
x1=max(a(1),b(1)); y1=max(a(2),b(2)); x2=min(a(1)+a(3),b(1)+b(3)); y2=min(a(2)+a(4),b(2)+b(4));
v=max(0,x2-x1)*max(0,y2-y1)/max(min(a(3)*a(4),b(3)*b(4)),eps);
end

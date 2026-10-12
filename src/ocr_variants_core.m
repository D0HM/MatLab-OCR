function [boxes, words, conf, source] = ocr_variants_core(I, cfg, ocrFcn)
% OCR_VARIANTS_CORE Run OCR on every FFT variant, map boxes back to the original
% image, keep letters/digits only, drop weak words, then merge duplicates by
% highest confidence (non-maximum suppression).
%   ocrFcn(img,layout) -> struct with Words, WordBoundingBoxes, WordConfidences (0..1)
% Returns boxes [x y w h] (original pixels), words (cellstr), conf, source (variant name).
V = fft_variants(I, cfg);
boxes = zeros(0,4); words = {}; conf = zeros(0,1); source = {};
layouts = getf(cfg,'F3Layouts',getf(cfg,'F3Layout','auto'));
if ischar(layouts) || isstring(layouts), layouts = cellstr(layouts); end
for k = 1:numel(V)
    for ell = 1:numel(layouts)
        r = ocrFcn(V(k).image, layouts{ell});
        w = cellstr(r.Words(:)); bb = double(r.WordBoundingBoxes); cf = double(r.WordConfidences(:));
        for j = 1:numel(w)
            t = regexprep(strtrim(w{j}), '^[^A-Za-z0-9]+|[^A-Za-z0-9]+$', '');
            if isempty(regexp(t, '^[A-Za-z0-9'']+$', 'once')), continue; end
            if numel(t) < cfg.F3MinChars || ~isfinite(cf(j)) || cf(j) < cfg.F3MinConfidence, continue; end
            b = bb(j,:);
            ob = [(b(1)-V(k).border-1)/V(k).sx+1, (b(2)-V(k).border-1)/V(k).sy+1, b(3)/V(k).sx, b(4)/V(k).sy];
            boxes(end+1,:) = ob; words{end+1,1} = t; conf(end+1,1) = cf(j); source{end+1,1} = [V(k).name '/' layouts{ell}]; %#ok<AGROW>
        end
    end
end
% Consensus vote: a real word is read the same way (case-insensitive) at overlapping
% boxes in several variants; one-off noise reads are dropped.
votes = zeros(numel(words),1);
for i = 1:numel(words)
    for j = 1:numel(words)
        if strcmpi(words{i}, words{j}) && box_iou(boxes(i,:), boxes(j,:)) >= cfg.F3NMSIoU
            votes(i) = votes(i) + 1;
        end
    end
end
vk = votes >= cfg.F3MinVotes;
boxes = boxes(vk,:); words = words(vk); conf = conf(vk); source = source(vk);
% Rank by confidence weighted by word length so partial reads ("PS") do not beat "PSD".
len = cellfun(@numel, words); [~, ord] = sort(conf(:).*sqrt(min(len(:),8)), 'descend');
keep = false(numel(ord),1); kept = zeros(0,1);
for i = ord(:)'
    ok = true;
    for j = kept(:)'
        if box_iou(boxes(i,:), boxes(j,:)) >= cfg.F3NMSIoU, ok = false; break; end
    end
    if ok, keep(i) = true; kept(end+1) = i; end %#ok<AGROW>
end
boxes = boxes(keep,:); words = words(keep); conf = conf(keep); source = source(keep);
end

function v = box_iou(a, b)
x1 = max(a(1),b(1)); y1 = max(a(2),b(2));
x2 = min(a(1)+a(3),b(1)+b(3)); y2 = min(a(2)+a(4),b(2)+b(4));
inter = max(0,x2-x1)*max(0,y2-y1);
v = inter/(a(3)*a(4)+b(3)*b(4)-inter);
end

function value = getf(cfg, name, fallback)
% GETF Reads an optional configuration field while keeping older configurations usable.
if isfield(cfg,name), value=cfg.(name); else, value=fallback; end
end

function [boxes, mask] = detect_mser_words(I, cfg)
% DETECT_MSER_WORDS Classical candidate detector; no OCR or GT used here.
% MSER regions -> geometric screening -> horizontal morphology -> boxes.
if ndims(I) == 3, G = rgb2gray(I); else, G = I; end
[~, cc] = detectMSERFeatures(G, 'RegionAreaRange', ...
    cfg.MSERAreaRange, 'ThresholdDelta', cfg.MSERThresholdDelta);
mask = false(size(G));
stats = regionprops(cc, 'BoundingBox', 'Area', 'Solidity');
for k = 1:numel(stats)
    b = stats(k).BoundingBox;
    ratio = b(3)/max(b(4),1);
    if b(4) >= cfg.MinCharHeight && b(4) <= size(G,1)*cfg.MaxCharHeightFraction ...
            && ratio >= cfg.MinCharAspect && ratio <= cfg.MaxCharAspect ...
            && stats(k).Solidity >= 0.1
        mask(cc.PixelIdxList{k}) = true;
    end
end
joined = imdilate(mask, strel('rectangle', [1 cfg.WordJoinPixels]));
groups = bwconncomp(joined);
boxes = zeros(0,4);
for k = 1:groups.NumObjects
    % Trim grouping dilation from the returned box using original pixels.
    idx = groups.PixelIdxList{k};
    idx = idx(mask(idx));
    if isempty(idx), continue; end
    [y,x] = ind2sub(size(G), idx);
    b = [min(x), min(y), max(x)-min(x)+1, max(y)-min(y)+1];
    if b(3) >= cfg.MinCandidateWidth && b(4) >= cfg.MinCandidateHeight
        boxes(end+1,:) = b; %#ok<AGROW>
    end
end
if ~isempty(boxes), boxes = boxes(reading_order(boxes),:); end
end

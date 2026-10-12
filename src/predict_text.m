function [pred, candidates, mask] = predict_text(P, detector, cfg)
% PREDICT_TEXT Keep candidate detection separate from recognized word output.
pred = table(zeros(0,1), zeros(0,1), zeros(0,1), zeros(0,1), ...
    strings(0,1), zeros(0,1), 'VariableNames', ...
    {'x','y','width','height','text','confidence'});
mask = false(size(P,1),size(P,2));
if string(detector) == "ocr"
    % Complementary layouts cover isolated textured words and multi-word scene text.
    layouts = get_layouts(cfg, 'OCRLayouts', cfg.OCRLayout);
    for k = 1:numel(layouts)
        r = ocr_compat(P, layouts{k}, cfg);
        pred = append_result(pred, r, [0 0], cfg);
    end
    pred = merge_overlapping_words(pred, cfg);
    % This is returned-word localization, NOT an independent detector.
    candidates = pred{:,1:4};
elseif string(detector) == "mser"
    [candidates, mask] = detect_mser_words(P, cfg);
    for k = 1:size(candidates,1)
        b = candidates(k,:);
        x1 = max(1,floor(b(1)-cfg.ROIPadding));
        y1 = max(1,floor(b(2)-cfg.ROIPadding));
        x2 = min(size(P,2),ceil(b(1)+b(3)-1+cfg.ROIPadding));
        y2 = min(size(P,1),ceil(b(2)+b(4)-1+cfg.ROIPadding));
        crop = P(y1:y2,x1:x2,:);
        r = ocr_compat(crop, 'block', cfg);
        pred = append_result(pred, r, [x1-1 y1-1], cfg);
    end
elseif string(detector) == "mser_refine"
    % Two-stage scene-text route: MSER proposes regions; OCR only sees padded crops.
    [candidates, mask] = detect_mser_words(P, cfg);
    candidates = prune_candidate_boxes(candidates, size(P), cfg);
    pred = recognize_candidate_crops(P, candidates, cfg);
    if isempty(pred)
        % MSER can return only texture fragments. Re-propose locations, then re-read their crops.
        proposals = full_image_proposals(P, cfg);
        candidates = prune_candidate_boxes(proposals{:,1:4}, size(P), cfg);
        pred = recognize_candidate_crops(P, candidates, cfg);
    end
else
    error('SceneText:Detector', 'Unknown detector: %s', detector);
end
if ~isempty(pred), pred = pred(reading_order(pred{:,1:4}),:); end
end

function layouts = get_layouts(cfg, fieldName, fallback)
% GET_LAYOUTS Supports the new list setting and saved configurations with one layout.
if isfield(cfg, fieldName), layouts = cfg.(fieldName); else, layouts = {fallback}; end
if ischar(layouts) || isstring(layouts), layouts = cellstr(layouts); end
end

function proposals = full_image_proposals(P, cfg)
% FULL_IMAGE_PROPOSALS Supplies crop locations when classical MSER has no stable region.
proposals = table(zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1),strings(0,1),zeros(0,1), ...
    'VariableNames',{'x','y','width','height','text','confidence'});
layouts = get_layouts(cfg, 'OCRLayouts', cfg.OCRLayout);
for k = 1:numel(layouts)
    proposals = append_result(proposals, ocr_compat(P, layouts{k}, cfg), [0 0], cfg);
end
proposals = merge_overlapping_words(proposals, cfg);
end

function pred = recognize_candidate_crops(P, candidates, cfg)
% RECOGNIZE_CANDIDATE_CROPS Runs OCR layouts only inside detector-selected regions.
pred = table(zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1),strings(0,1),zeros(0,1), ...
    'VariableNames',{'x','y','width','height','text','confidence'});
layouts = get_layouts(cfg, 'CropOCRLayouts', 'word');
for k = 1:size(candidates,1)
    b = candidates(k,:);
    x1 = max(1,floor(b(1)-cfg.ROIPadding)); y1 = max(1,floor(b(2)-cfg.ROIPadding));
    x2 = min(size(P,2),ceil(b(1)+b(3)-1+cfg.ROIPadding)); y2 = min(size(P,1),ceil(b(2)+b(4)-1+cfg.ROIPadding));
    crop = P(y1:y2,x1:x2,:);
    for ell = 1:numel(layouts)
        % The crop is already F1/F2 frequency-preprocessed by run_experiment.
        pred = append_result(pred, ocr_compat(crop, layouts{ell}, cfg), [x1-1 y1-1], cfg);
    end
end
pred = merge_overlapping_words(pred, cfg);
end

function pred = merge_overlapping_words(pred, cfg)
% MERGE_OVERLAPPING_WORDS Removes duplicate and contained OCR reads after crop refinement.
if height(pred) < 2, return; end
boxes = pred{:,1:4}; score = pred.confidence.*sqrt(min(strlength(pred.text),8)); score(~isfinite(score)) = -inf;
[~, order] = sort(score, 'descend'); keep = false(height(pred),1); kept = zeros(0,1);
for i = order(:)'
    overlaps = false;
    for j = kept(:)'
        if box_iou_layout(boxes(i,:), boxes(j,:)) >= cfg.ResultNMSIoU ...
                || contained_fraction(boxes(i,:), boxes(j,:)) >= cfg.ResultContainment
            overlaps = true; break;
        end
    end
    if ~overlaps, keep(i) = true; kept(end+1) = i; end %#ok<AGROW>
end
pred = pred(keep,:);
end

function value = contained_fraction(a, b)
% CONTAINED_FRACTION Detects nested boxes that ordinary IoU does not suppress.
x1=max(a(1),b(1)); y1=max(a(2),b(2));
x2=min(a(1)+a(3),b(1)+b(3)); y2=min(a(2)+a(4),b(2)+b(4));
intersection=max(0,x2-x1)*max(0,y2-y1);
value=intersection/max(min(a(3)*a(4),b(3)*b(4)),eps);
end

function value = box_iou_layout(a, b)
% BOX_IOU_LAYOUT Computes overlap for multi-layout non-maximum suppression.
x1=max(a(1),b(1)); y1=max(a(2),b(2));
x2=min(a(1)+a(3),b(1)+b(3)); y2=min(a(2)+a(4),b(2)+b(4));
inter=max(0,x2-x1)*max(0,y2-y1);
value=inter/(a(3)*a(4)+b(3)*b(4)-inter);
end

function pred = append_result(pred, r, offset, cfg)
words = string(r.Words(:));
% The project scope is English letters and digits; discard OCR punctuation around a valid word.
words = regexprep(strtrim(words), '^[^A-Za-z0-9]+|[^A-Za-z0-9]+$', '');
boxes = double(r.WordBoundingBoxes);
conf = double(r.WordConfidences(:));
minChars = 1; if isfield(cfg,'MinRecognizedChars'), minChars = cfg.MinRecognizedChars; end
keep = strlength(words) >= minChars & ~cellfun(@isempty,regexp(cellstr(words),'^[A-Za-z0-9]+$','once')) ...
    & all(isfinite(boxes),2) ...
    & boxes(:,3) > 0 & boxes(:,4) > 0;
% At the default zero threshold, retain NaN confidences as unknown confidence.
if cfg.MinConfidence > 0
    keep = keep & isfinite(conf) & conf >= cfg.MinConfidence;
end
boxes = boxes(keep,:);
boxes(:,1:2) = boxes(:,1:2) + offset;
rows = table(boxes(:,1),boxes(:,2),boxes(:,3),boxes(:,4), ...
    words(keep),conf(keep), 'VariableNames', pred.Properties.VariableNames);
pred = [pred; rows];
end

function [pred, candidates, mask] = predict_text(P, detector, cfg)
% PREDICT_TEXT Keep candidate detection separate from recognized word output.
pred = table(zeros(0,1), zeros(0,1), zeros(0,1), zeros(0,1), ...
    strings(0,1), zeros(0,1), 'VariableNames', ...
    {'x','y','width','height','text','confidence'});
mask = false(size(P,1),size(P,2));
if string(detector) == "ocr"
    r = ocr_compat(P, cfg.OCRLayout, cfg);
    pred = append_result(pred, r, [0 0], cfg);
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
else
    error('SceneText:Detector', 'Unknown detector: %s', detector);
end
if ~isempty(pred), pred = pred(reading_order(pred{:,1:4}),:); end
end

function pred = append_result(pred, r, offset, cfg)
words = string(r.Words(:));
boxes = double(r.WordBoundingBoxes);
conf = double(r.WordConfidences(:));
keep = strlength(strtrim(words)) > 0 & all(isfinite(boxes),2) ...
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

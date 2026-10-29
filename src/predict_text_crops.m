function [pred, candidates] = predict_text_crops(I, cfg)
% PREDICT_TEXT_CROPS Method F4: MSER (on the F2 FFT image) proposes boxes, then every box is read with
% per-crop FFT variants + voting (ocr_crops_core). Output table matches predict_text.
% Needs Computer Vision Toolbox (MSER + ocr). Runtime ~ crops x variants OCR calls per image.
[P, ~] = preprocess_image(I, 'F2', cfg);
[candidates, ~] = detect_mser_words(P, cfg);
candidates = prune_candidate_boxes(candidates, size(P), cfg);
if isempty(candidates)
    [~, candidates] = predict_text(P, 'ocr', cfg);   % fall back to OCR word boxes as proposals
end
[boxes, words, conf] = ocr_crops_core(I, candidates, cfg, @(img,layout) ocr_compat(img, layout, cfg));
pred = table(boxes(:,1), boxes(:,2), boxes(:,3), boxes(:,4), string(words(:)), conf(:), ...
    'VariableNames', {'x','y','width','height','text','confidence'});
if ~isempty(pred), pred = pred(reading_order(pred{:,1:4}),:); end
end

function [pred, candidates] = predict_text_variants(I, cfg)
% PREDICT_TEXT_VARIANTS Method F3 OCR: multi-variant FFT preprocessing + OCR + merge.
% Output table matches predict_text (x,y,width,height,text,confidence); coordinates
% are in the ORIGINAL image. WARNING: runs numel(variants) OCR calls per image
% (default 18); CPU-only is slow (~1-3 min/image).
% Use automatic and single-word OCR layouts for each frequency-domain candidate.
[boxes, words, conf] = ocr_variants_core(I, cfg, @(img,layout) ocr_compat(img, layout, cfg));
pred = table(boxes(:,1), boxes(:,2), boxes(:,3), boxes(:,4), string(words(:)), conf(:), ...
    'VariableNames', {'x','y','width','height','text','confidence'});
if ~isempty(pred), pred = pred(reading_order(pred{:,1:4}),:); end
candidates = pred{:,1:4};
end

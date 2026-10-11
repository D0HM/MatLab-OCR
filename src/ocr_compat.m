function r = ocr_compat(I, layout, cfg)
% OCR_COMPAT Use documented release-specific names, not silent retries.
if verLessThan('matlab', '9.14') % R2023a renamed these arguments.
    r = ocr(I, 'Language', cfg.Language, 'TextLayout', layout);
else
    r = ocr(I, 'Model', cfg.Language, 'LayoutAnalysis', layout);
end
end

function s = normalize_text(s, cfg)
% NORMALIZE_TEXT Policy is shared by GT and predictions and recorded in config.
s = string(s);
if ~cfg.CaseSensitive, s = lower(s); end
if ~cfg.KeepPunctuation, s = regexprep(s, '[^a-zA-Z0-9\s]', ''); end
s = strtrim(regexprep(s, '\s+', ' '));
end

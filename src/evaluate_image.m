function [metrics, words] = evaluate_image(gt,pred,candidates,cfg)
% EVALUATE_IMAGE Counts missed GT and unmatched predictions explicitly.
gb = gt{:,{'x','y','width','height'}};
pb = pred{:,{'x','y','width','height'}};
[pairs, ious] = match_boxes(gb,pb,cfg.IoUThreshold);
[detPairs,~] = match_boxes(gb,candidates,cfg.IoUThreshold);
n = height(gt); m = height(pred);
assigned = zeros(n,1);
assigned(pairs(:,1)) = pairs(:,2);
matchedPred = false(m,1); matchedPred(pairs(:,2)) = true;
records = struct('WordIndex',{},'Status',{},'Expected',{},'Recognized',{}, ...
    'Confidence',{},'IoU',{},'RecognitionRatePct',{},'Exact',{});
rates = zeros(n,1); exact = false(n,1);
for g = 1:n
    p = assigned(g);
    expected = normalize_text(gt.text(g),cfg);
    recognized = ""; confidence = NaN; iou = 0; status = "missed";
    if p > 0
        recognized = normalize_text(pred.text(p),cfg);
        confidence = pred.confidence(p); iou = ious(g,p); status = "matched";
    end
    rates(g) = 100*max(0,1-edit_distance(char(expected),char(recognized)) ...
        /max(1,strlength(expected)));
    exact(g) = expected == recognized && p > 0;
    records(end+1) = struct('WordIndex',gt.word_index(g), ...
        'Status',status,'Expected',string(gt.text(g)), ...
        'Recognized',recognized,'Confidence',confidence,'IoU',iou, ...
        'RecognitionRatePct',rates(g),'Exact',exact(g)); %#ok<AGROW>
end
for p = find(~matchedPred)'
    records(end+1) = struct('WordIndex',0,'Status',"false_positive", ...
        'Expected',"",'Recognized',pred.text(p), ...
        'Confidence',pred.confidence(p),'IoU',0, ...
        'RecognitionRatePct',NaN,'Exact',false); %#ok<AGROW>
end
if isempty(records)
    words = table(zeros(0,1),strings(0,1),strings(0,1),strings(0,1), ...
        zeros(0,1),zeros(0,1),zeros(0,1),false(0,1), ...
        'VariableNames',{'WordIndex','Status','Expected','Recognized', ...
        'Confidence','IoU','RecognitionRatePct','Exact'});
else
    words = struct2table(records);
end
% Standard sequence CER / WER: GT label order versus geometric prediction order.
if isempty(gt), expectedText=""; else, expectedText=join(gt.text," "); end
if isempty(pred), recognizedText=""; else, recognizedText=join(pred.text," "); end
expectedText = normalize_text(expectedText,cfg);
recognizedText = normalize_text(recognizedText,cfg);
expectedChars = char(expectedText); recognizedChars = char(recognizedText);
expectedTokens = tokenize(expectedText); recognizedTokens = tokenize(recognizedText);
metrics.GTWords = n;
metrics.PredWords = m;
metrics.CandidateBoxes = size(candidates,1);
metrics.DetTP = size(detPairs,1);
metrics.DetFP = size(candidates,1)-metrics.DetTP;
metrics.DetFN = n-metrics.DetTP;
metrics.DetPrecision = safe_ratio(metrics.DetTP,metrics.DetTP+metrics.DetFP);
metrics.DetRecall = safe_ratio(metrics.DetTP,metrics.DetTP+metrics.DetFN);
metrics.DetF1 = safe_ratio(2*metrics.DetTP,2*metrics.DetTP+metrics.DetFP+metrics.DetFN);
metrics.WordTP = size(pairs,1);
metrics.WordFP = m-metrics.WordTP;
metrics.WordFN = n-metrics.WordTP;
metrics.ExactWords = sum(exact);
metrics.ExactWordRatePct = 100*safe_ratio(sum(exact),n);
metrics.RecognitionRatePct = mean(rates); % Missed GT words contribute zero.
metrics.CharEdits = edit_distance(expectedChars,recognizedChars);
metrics.GTChars = numel(expectedChars);
metrics.CER = safe_ratio(metrics.CharEdits,metrics.GTChars);
metrics.WordEdits = edit_distance(expectedTokens,recognizedTokens);
metrics.GTTokens = numel(expectedTokens);
metrics.WER = safe_ratio(metrics.WordEdits,metrics.GTTokens);
metrics.AvgConfidence = mean(pred.confidence(isfinite(pred.confidence)));
metrics.ExpectedText = expectedText;
metrics.RecognizedText = recognizedText;
end

function t = tokenize(s)
if strlength(s) == 0, t = strings(0,1); else, t = split(s," "); end
end

function r = safe_ratio(a,b)
% Undefined denominator is NaN, not an artificial perfect score.
if b == 0, r = NaN; else, r = a/b; end
end

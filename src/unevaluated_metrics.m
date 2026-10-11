function [m,words] = unevaluated_metrics(gt,pred,candidates)
% UNEVALUATED_METRICS Display real OCR output but do not score draft labels.
m.GTWords=height(gt); m.PredWords=height(pred); m.CandidateBoxes=size(candidates,1);
names={'DetTP','DetFP','DetFN','DetPrecision','DetRecall','DetF1', ...
    'WordTP','WordFP','WordFN','ExactWords','ExactWordRatePct', ...
    'RecognitionRatePct','CharEdits','GTChars','CER','WordEdits','GTTokens','WER'};
for k=1:numel(names), m.(names{k})=NaN; end
m.AvgConfidence=mean(pred.confidence(isfinite(pred.confidence)));
if isempty(gt), m.ExpectedText=""; else, m.ExpectedText=join(gt.text," "); end
if isempty(pred), m.RecognizedText=""; else, m.RecognizedText=join(pred.text," "); end
words=table();
end

function tests=test_metrics
tests=functiontests(localfunctions);
end

function testEditDistance(t)
verifyEqual(t,edit_distance('kitten','sitting'),3);
verifyEqual(t,edit_distance('','abc'),3);
verifyEqual(t,edit_distance('abc',''),3);
verifyEqual(t,edit_distance(["one";"two"],["one";"three";"two"]),1);
end

function testPerfect(t)
[cfg,gt,p]=fixture();
[m,w]=evaluate_image(gt,p,p{:,1:4},cfg);
verifyEqual(t,m.DetF1,1);
verifyEqual(t,m.CER,0);
verifyEqual(t,m.WER,0);
verifyEqual(t,m.RecognitionRatePct,100);
verifyEqual(t,sum(w.Status=="matched"),2);
end

function testMissingWord(t)
[cfg,gt,p]=fixture(); p=p(1,:);
[m,w]=evaluate_image(gt,p,p{:,1:4},cfg);
verifyEqual(t,m.DetFN,1);
verifyEqual(t,m.RecognitionRatePct,50);
verifyEqual(t,m.WER,0.5);
verifyEqual(t,sum(w.Status=="missed"),1);
end

function testFalsePositive(t)
[cfg,gt,p]=fixture();
p=[p;table(200,10,20,20,"fake",0.99,'VariableNames',p.Properties.VariableNames)];
[m,w]=evaluate_image(gt,p,p{:,1:4},cfg);
verifyEqual(t,m.DetFP,1);
verifyEqual(t,m.WER,0.5);
verifyEqual(t,m.RecognitionRatePct,100); % Macro GT rate excludes FP; WER includes it.
verifyEqual(t,sum(w.Status=="false_positive"),1);
end

function testNoPrediction(t)
[cfg,gt,p]=fixture(); p=p([],:);
[m,~]=evaluate_image(gt,p,zeros(0,4),cfg);
verifyEqual(t,m.DetF1,0);
verifyEqual(t,m.CER,1);
verifyEqual(t,m.WER,1);
verifyEqual(t,m.RecognitionRatePct,0);
verifyTrue(t,isnan(m.AvgConfidence));
end

function testHighConfidenceWrongText(t)
[cfg,gt,p]=fixture(); p.text(1)="wrong"; p.confidence(1)=0.99;
[m,~]=evaluate_image(gt,p,p{:,1:4},cfg);
verifyEqual(t,m.ExactWords,1);
verifyGreaterThan(t,m.CER,0);
verifyGreaterThan(t,m.AvgConfidence,0.9);
end

function testCasePolicy(t)
[cfg,gt,p]=fixture(); p.text(1)="HELLO";
[m,~]=evaluate_image(gt,p,p{:,1:4},cfg); verifyEqual(t,m.CER,0);
cfg.CaseSensitive=true;
[m,~]=evaluate_image(gt,p,p{:,1:4},cfg); verifyGreaterThan(t,m.CER,0);
end

function testDuplicatePrediction(t)
[cfg,gt,p]=fixture(); p=[p;p(1,:)];
[m,~]=evaluate_image(gt,p,p{:,1:4},cfg);
verifyEqual(t,m.DetTP,2); verifyEqual(t,m.DetFP,1);
end

function testMatchingAugmentingPath(t)
% g1 can match p1 or p2; g2 only p1. Greedy could miss g2.
g=[1 1 10 10;5 1 10 10]; p=[2 1 10 10;1 1 6 10];
[pairs,~]=match_boxes(g,p,0.5);
verifyEqual(t,size(pairs,1),2);
verifyEqual(t,numel(unique(pairs(:,2))),2);
end

function testReadingOrder(t)
b=[100 10 20 20;10 40 20 20;10 10 20 20];
verifyEqual(t,reading_order(b),[3;1;2]);
end

function testNegativeImage(t)
[cfg,gt,p]=fixture(); gt=gt([],:);
[m,~]=evaluate_image(gt,p,p{:,1:4},cfg);
verifyEqual(t,m.DetFP,2); verifyEqual(t,m.DetF1,0);
verifyTrue(t,isnan(m.CER)); verifyTrue(t,isnan(m.RecognitionRatePct));
end

function testEmptyNegativeImage(t)
[cfg,gt,p]=fixture(); gt=gt([],:); p=p([],:);
[m,w]=evaluate_image(gt,p,zeros(0,4),cfg);
verifyEqual(t,m.DetFP,0); verifyTrue(t,isnan(m.DetF1));
verifyTrue(t,isnan(m.CER)); verifyEqual(t,height(w),0);
end

function testSummaryPooling(t)
[cfg,gt,p]=fixture();
[m,~]=evaluate_image(gt,p,p{:,1:4},cfg);
m.Detector="ocr";m.Method="M0";m.Texture="simple";m.Seconds=1;
[missing,~]=evaluate_image(gt(1,:),p([],:),zeros(0,4),cfg);
missing.Detector="ocr";missing.Method="M0";missing.Texture="simple";missing.Seconds=3;
r=[struct2table(m);struct2table(missing)]; s=summarize_results(r,cfg);
verifyEqual(t,height(s),2); % The texture row and the ALL row.
verifyEqual(t,s.Images,[2;2]);
verifyEqual(t,s.ScoredImages,[2;2]);
verifyEqual(t,s.DetTP,[2;2]); verifyEqual(t,s.DetFN,[1;1]);
verifyEqual(t,s.DetF1,[0.8;0.8],'AbsTol',1e-12);
verifyEqual(t,s.CER,[5/16;5/16],'AbsTol',1e-12);
verifyEqual(t,s.WER,[1/3;1/3],'AbsTol',1e-12);
verifyEqual(t,s.RecognitionRatePct,[50;50]);
verifyEqual(t,s.ExactWordRatePct,[200/3;200/3],'AbsTol',1e-12);
verifyEqual(t,s.SecondsPerImage,[2;2]);
end

function testSummaryMultipleGroups(t)
[cfg,gt,p]=fixture(); cfg.Methods=["M0","F1"];
[m,~]=evaluate_image(gt,p,p{:,1:4},cfg);
m.Detector="ocr";m.Method="M0";m.Texture="simple";m.Seconds=1;
r=struct2table(m);
other=r; other.Method="F1"; other.Texture="moderate"; other.Seconds=3;
s=summarize_results([r;other],cfg);
verifyEqual(t,height(s),4);
verifyEqual(t,s.Images,ones(4,1));
verifyEqual(t,s.DetF1,ones(4,1));
verifyEqual(t,s.SecondsPerImage(s.Method=="M0" & s.Texture=="ALL"),1);
verifyEqual(t,s.SecondsPerImage(s.Method=="F1" & s.Texture=="ALL"),3);
end

function testSummaryDraftOnly(t)
[cfg,gt,p]=fixture();
[m,~]=unevaluated_metrics(gt,p,p{:,1:4});
m.Detector="ocr";m.Method="M0";m.Texture="simple";m.Seconds=1;m.Evaluated=false;
s=summarize_results(struct2table(m),cfg);
verifyEqual(t,height(s),2);
verifyEqual(t,s.Images,[1;1]); verifyEqual(t,s.ScoredImages,[0;0]);
verifyEqual(t,s.AvgReturnedWords,[2;2]);
verifyEqual(t,s.AvgConfidence,[0.95;0.95],'AbsTol',1e-12);
fields={'RecognitionRatePct','ExactWordRatePct','DetTP','DetFP','DetFN', ...
    'DetPrecision','DetRecall','DetF1','CER','WER'};
verifyTrue(t,all(all(isnan(s{:,fields}))));
end

function testSummaryMixedReviewStatus(t)
[cfg,gt,p]=fixture();
[m,~]=evaluate_image(gt,p,p{:,1:4},cfg);
m.Detector="ocr";m.Method="M0";m.Texture="simple";m.Seconds=1;m.Evaluated=true;
r=struct2table(m);
p.text(:)="wrong"; p.confidence(:)=0.8;
[draft,~]=unevaluated_metrics(gt,p,p{:,1:4});
draft.Detector="ocr";draft.Method="M0";draft.Texture="simple";draft.Seconds=3;
draft.Evaluated=false;
other=struct2table(draft);
other=other(:,r.Properties.VariableNames); % Evaluated/draft metric field order differs.
s=summarize_results([r;other],cfg);
verifyEqual(t,s.Images,[2;2]); verifyEqual(t,s.ScoredImages,[1;1]);
verifyEqual(t,s.DetF1,[1;1]); verifyEqual(t,s.CER,[0;0]);
verifyEqual(t,s.RecognitionRatePct,[100;100]);
verifyEqual(t,s.AvgConfidence,[0.875;0.875],'AbsTol',1e-12);
verifyEqual(t,s.SecondsPerImage,[2;2]);
end

function [cfg,gt,p]=fixture()
cfg=project_config();
gt=table(["a";"a"],[1;2],[10;80],[10;10],[50;50],[20;20], ...
    ["hello";"world"],'VariableNames', ...
    {'image_id','word_index','x','y','width','height','text'});
p=table([10;80],[10;10],[50;50],[20;20],["hello";"world"],[0.95;0.95], ...
    'VariableNames',{'x','y','width','height','text','confidence'});
end

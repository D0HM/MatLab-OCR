function summary = summarize_results(results,cfg)
% SUMMARIZE_RESULTS Macro image recognition/confidence; pooled detection/CER/WER.
rows=struct([]);
for detector=cfg.Detectors
    for method=cfg.Methods
        for texture=[unique(results.Texture,'stable')',"ALL"]
            use=results.Detector==detector & results.Method==method;
            if texture~="ALL", use=use & results.Texture==texture; end
            r=results(use,:);
            if isempty(r), continue; end
            row.Detector=detector; row.Method=method; row.Texture=texture;
            row.Images=height(r);
            if ismember('Evaluated',r.Properties.VariableNames)
                scored=r(r.Evaluated,:);
            else
                scored=r;
            end
            row.ScoredImages=height(scored);
            row.AvgConfidence=mean(r.AvgConfidence,'omitnan');
            row.AvgReturnedWords=mean(r.PredWords);
            row.RecognitionRatePct=mean(scored.RecognitionRatePct,'omitnan');
            row.ExactWordRatePct=100*ratio(sum(scored.ExactWords),sum(scored.GTWords));
            row.DetTP=sum(scored.DetTP); row.DetFP=sum(scored.DetFP); row.DetFN=sum(scored.DetFN);
            if isempty(scored), row.DetTP=NaN; row.DetFP=NaN; row.DetFN=NaN; end
            row.DetPrecision=ratio(row.DetTP,row.DetTP+row.DetFP);
            row.DetRecall=ratio(row.DetTP,row.DetTP+row.DetFN);
            row.DetF1=ratio(2*row.DetTP,2*row.DetTP+row.DetFP+row.DetFN);
            row.CER=ratio(sum(scored.CharEdits),sum(scored.GTChars));
            row.WER=ratio(sum(scored.WordEdits),sum(scored.GTTokens));
            row.SecondsPerImage=mean(r.Seconds);
            % Seed the schema before indexed assignment to a fieldless struct.
            if isempty(rows)
                rows=row;
            else
                rows(end+1)=row; %#ok<AGROW>
            end
        end
    end
end
summary=struct2table(rows);
end

function r=ratio(a,b)
if b==0, r=NaN; else, r=a/b; end
end

function plot_results(summary,outDir)
% PLOT_RESULTS Never combine distinct detector definitions on a single score.
for detector=unique(summary.Detector)'
    r=summary(summary.Detector==detector,:);
    methods=unique(r.Method,'stable');
    textures=unique(r.Texture(r.Texture~="ALL"),'stable')';
    values=NaN(numel(textures),numel(methods)); f1=values;
    for t=1:numel(textures)
        for m=1:numel(methods)
            use=r.Texture==textures(t) & r.Method==methods(m);
            if any(use)
                if all(r.ScoredImages==0)
                    values(t,m)=r.AvgConfidence(find(use,1));
                    f1(t,m)=r.AvgReturnedWords(find(use,1));
                else
                    values(t,m)=r.RecognitionRatePct(find(use,1));
                    f1(t,m)=100*r.DetF1(find(use,1));
                end
            end
        end
    end
    fig=figure('Visible','off','Color','white','Position',[100 100 1100 420]);
    cleanup=onCleanup(@() close(fig));
    subplot(1,2,1); bar(values); grid on;
    xticklabels(textures); legend(methods,'Location','best');
    if all(r.ScoredImages==0)
        ylim([0 1]); ylabel('Mean OCR confidence');
        title(detector+' | confidence is NOT accuracy');
    else
        ylim([0 100]); ylabel('Recognition rate (%)');
        title(detector+' | missed GT words score zero');
    end
    subplot(1,2,2); bar(f1); grid on;
    xticklabels(textures); legend(methods,'Location','best');
    if all(r.ScoredImages==0)
        ylabel('Mean returned word boxes'); title('More boxes does NOT mean better recognition');
    else
        ylim([0 100]); ylabel('Detection F1 (%)'); title(detector+' | IoU matching');
    end
    exportgraphics(fig,fullfile(outDir,char('chart_'+detector+'.png')),'Resolution',180);
    clear cleanup;
end
end

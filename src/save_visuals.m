function save_visuals(I,P,gt,pred,candidates,outDir,cfg)
% SAVE_VISUALS Original, preprocessing and overlay for slides/failure analysis.
if size(I,3)==1, I=repmat(I,1,1,3); end
if size(P,3)==1, P=repmat(P,1,1,3); end
overlay = I;
if ~isempty(gt)
    overlay = insertShape(overlay,'Rectangle',gt{:,{'x','y','width','height'}}, ...
        'Color','green','LineWidth',2);
end
if ~isempty(candidates)
    overlay = insertShape(overlay,'Rectangle',candidates,'Color','yellow','LineWidth',2);
end
if ~isempty(pred)
    labels = pred.text + " [" + compose('%.2f',pred.confidence) + "]";
    overlay = insertObjectAnnotation(overlay,'rectangle',pred{:,1:4}, ...
        cellstr(labels),'Color','cyan','LineWidth',2,'FontSize',14);
end
imwrite(I,fullfile(outDir,'original.png'));
imwrite(overlay,fullfile(outDir,'overlay.png'));
if cfg.SaveFigures
    fig=figure('Visible','off','Color','white','Position',[100 100 1500 480]);
    cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
    subplot(1,3,1); imshow(I); title('Original');
    subplot(1,3,2); imshow(P); title('Processed');
    subplot(1,3,3); imshow(overlay);
    title({'Green: reference GT (draft until reviewed) | Yellow: candidates', ...
        'Cyan: recognized words + confidence'});
    exportgraphics(fig,fullfile(outDir,'comparison.png'),'Resolution',160);
end
end

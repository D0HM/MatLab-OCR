function save_frequency_visuals(stages,outDir,cfg)
% SAVE_FREQUENCY_VISUALS Export evidence of the actual frequency operations.
if ~cfg.SaveFigures, return; end
prefixes=["fft_illumination","fft_texture","fft_highboost"];
available=prefixes(arrayfun(@(p) isfield(stages,char(p+'_spectrum')),prefixes));
if isempty(available), return; end
fig=figure('Visible','off','Color','white','Position',[100 100 1400 340*numel(available)]);
cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
suffixes=["spectrum","transfer","filtered_spectrum","reconstructed"];
labels=["log(1+|F|)","Transfer H(u,v)","log(1+|F H|)","Reconstructed (padded)"];
for r=1:numel(available)
    for c=1:4
        subplot(numel(available),4,(r-1)*4+c);
        imshow(stages.(char(available(r)+'_'+suffixes(c))));
        title({char(available(r)),char(labels(c))},'Interpreter','none');
    end
end
exportgraphics(fig,fullfile(outDir,'frequency_comparison.png'),'Resolution',160);
end

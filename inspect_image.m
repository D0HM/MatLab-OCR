function outDir = inspect_image(path,method,detector)
% INSPECT_IMAGE Predict on one photograph without GT. No accuracy is invented.
root=fileparts(mfilename('fullpath'));
srcDir=fullfile(root,'src');
requiredFiles={fullfile(root,'project_config.m'),fullfile(root,'check_requirements.m'), ...
    fullfile(srcDir,'read_image.m'),fullfile(srcDir,'preprocess_image.m'), ...
    fullfile(srcDir,'predict_text.m'),fullfile(srcDir,'save_visuals.m'), ...
    fullfile(srcDir,'save_frequency_visuals.m')};
if ~isfolder(srcDir) || ~all(cellfun(@isfile,requiredFiles))
    error('SceneTextTexture:IncompleteProject', ...
        ['The project files are missing next to inspect_image.m.\n' ...
         'Loaded file: %s\nExpected source folder: %s\n' ...
         'Extract the entire ZIP, keeping its folders. Open SceneTextTextureMATLAB\n' ...
         'as the MATLAB Current Folder, then run inspect_image again.\n' ...
         'Use "which inspect_image -all" to locate duplicate copies.'], ...
         mfilename('fullpath'),srcDir);
end
addpath(root,srcDir,'-begin');
if nargin<1
    [name,folder]=uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif','Images'});
    if isequal(name,0), outDir=''; return; end
    path=fullfile(folder,name);
end
if nargin<2, method='F1'; end
if nargin<3, detector='ocr'; end
check_requirements(); cfg=project_config('provided');
I=read_image(path); [P,stages]=preprocess_image(I,method,cfg);
[pred,candidates,~]=predict_text(P,detector,cfg);
if ~isfolder(cfg.OutputRoot), mkdir(cfg.OutputRoot); end
[~,token]=fileparts(tempname); outDir=fullfile(cfg.OutputRoot,['single_' token]); mkdir(outDir);
emptyGT=table(zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1), ...
    'VariableNames',{'x','y','width','height'});
save_visuals(I,P,emptyGT,pred,candidates,outDir,cfg);
if any(startsWith(string(fieldnames(stages)),"fft_"))
    save_frequency_visuals(stages,outDir,cfg);
end
writetable(pred,fullfile(outDir,'predicted_words.csv'));
disp(pred); fprintf('No GT supplied: accuracy was NOT evaluated. Output: %s\n',outDir);
end

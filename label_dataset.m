function label_dataset()
% LABEL_DATASET Interactive word-level ground truth with incremental saves.
% Place photos in data/real/images. Run from the project folder in MATLAB.
root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'src'));
check_requirements();
dataDir=fullfile(root,'data','real'); imageDir=fullfile(dataDir,'images');
if ~isfolder(imageDir), mkdir(imageDir); end
manifestPath=fullfile(dataDir,'manifest.csv'); gtPath=fullfile(dataDir,'ground_truth.csv');
manifest=table(strings(0,1),strings(0,1),strings(0,1),strings(0,1),strings(0,1),zeros(0,1), ...
    'VariableNames',{'image_id','filename','texture','split','source','has_text'});
gt=table(strings(0,1),zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1),strings(0,1), ...
    'VariableNames',{'image_id','word_index','x','y','width','height','text'});
if isfile(manifestPath), manifest=readtable(manifestPath,'TextType','string'); end
if isfile(gtPath), gt=readtable(gtPath,'TextType','string'); end
files=dir(imageDir); files=files(~[files.isdir]);
extensions=[".jpg",".jpeg",".png",".bmp",".tif",".tiff"];
for k=1:numel(files)
    [~,~,ext]=fileparts(files(k).name);
    if ~ismember(lower(string(ext)),extensions), continue; end
    name=string(files(k).name);
    if any(manifest.filename==name), continue; end % Resume without relabelling saved images.
    meta=inputdlg({'Texture: simple / moderate / complex', ...
        'Split: dev / test','Photo source / attribution'}, ...
        char('Metadata: '+name),[1 60],{'moderate','dev','own_photo'});
    if isempty(meta), break; end
    texture=lower(strtrim(string(meta{1}))); split=lower(strtrim(string(meta{2})));
    if ~ismember(texture,["simple","moderate","complex"]) || ~ismember(split,["dev","test"])
        errordlg('Invalid texture/split. Rerun to label this image.'); break;
    end
    I=read_image(fullfile(imageDir,name));
    fig=figure('Name',char(name),'NumberTitle','off'); imshow(I);
    title('Label EVERY readable word in reading order. Cancel the word dialog when done.');
    id="real_"+compose('%04d',height(manifest)+1);
    while any(manifest.image_id==id), id=id+"x"; end
    pending=gt([],:); index=1;
    while isgraphics(fig)
        answer=inputdlg('Enter the exact next WORD (Cancel = finish image)', ...
            'Ground truth',[1 60]);
        if isempty(answer), break; end
        word=strtrim(string(answer{1}));
        if strlength(word)==0 || ~isempty(regexp(char(word),'\s','once'))
            errordlg('Enter exactly one word, including punctuation if present.'); continue;
        end
        figure(fig);
        title(char('Draw a tight box around: '+word+'; double-click to accept.'));
        roi=drawrectangle('Color','green'); wait(roi);
        if ~isvalid(roi), continue; end
        b=roi.Position;
        x=max(1,floor(b(1))); y=max(1,floor(b(2)));
        right=min(size(I,2)+1,ceil(b(1)+b(3)));
        bottom=min(size(I,1)+1,ceil(b(2)+b(4)));
        if right<=x || bottom<=y, delete(roi); continue; end
        pending=[pending; table(id,index,x,y,right-x,bottom-y,word, ...
            'VariableNames',gt.Properties.VariableNames)]; %#ok<AGROW>
        roi.Label=char(word); index=index+1;
    end
    if isgraphics(fig), close(fig); end
    answer=questdlg('Have you labelled every readable word? Saving zero words marks a negative image.', ...
        'Save image annotations','Save','Skip','Stop','Save');
    if strcmp(answer,'Stop') || isempty(answer), break; end
    if strcmp(answer,'Skip'), continue; end
    manifest=[manifest;table(id,name,texture,split,string(meta{3}),double(height(pending)>0), ...
        'VariableNames',manifest.Properties.VariableNames)]; %#ok<AGROW>
    gt=[gt;pending]; %#ok<AGROW>
    writetable(manifest,manifestPath); writetable(gt,gtPath);
    fprintf('Saved %s (%d words)\n',name,height(pending));
end
fprintf('Annotations saved in %s\n',dataDir);
end

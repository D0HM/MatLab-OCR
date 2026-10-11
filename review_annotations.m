function review_annotations()
% REVIEW_ANNOTATIONS Refine seed boxes and add missing words before accuracy scoring.
% Predictions always use the full image; annotations never define OCR input ROIs.
root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'src'));
cfg=project_config('provided');
[images,gtAll]=load_dataset(cfg);
for k=1:height(images)
    id=images.image_id(k);
    if images.annotation_status(k)=="reviewed", continue; end
    I=read_image(fullfile(cfg.DataDir,'images',images.filename(k)));
    current=sortrows(gtAll(gtAll.image_id==id,:),'word_index');
    pending=current([],:);
    fig=figure('Name',char(id),'NumberTitle','off'); imshow(I);
    title('Draft labels: correct text and boxes, then add EVERY missing readable word.');
    abandoned=false;
    for n=1:height(current)
        answer=inputdlg({'Correct one-word label (blank = remove this draft box)'}, ...
            char(id),[1 70],{char(current.text(n))});
        if isempty(answer), abandoned=true; break; end
        word=strtrim(string(answer{1}));
        if strlength(word)==0, continue; end
        assert(isempty(regexp(char(word),'\s','once')),'Use one word per box.');
        figure(fig);
        title(char('Adjust box for '+word+'; DOUBLE-CLICK to accept.'));
        roi=drawrectangle('Position',current{n,{'x','y','width','height'}}, ...
            'Color','green','Label',char(word));
        wait(roi);
        if ~isvalid(roi), abandoned=true; break; end
        b=clamp_box(roi.Position,size(I));
        row=table(id,0,b(1),b(2),b(3),b(4),word,'VariableNames',current.Properties.VariableNames);
        pending=[pending;row]; %#ok<AGROW>
    end
    if abandoned
        if isgraphics(fig), close(fig); end
        break;
    end
    while isgraphics(fig)
        answer=inputdlg('Add another readable WORD (Cancel = finish adding)', ...
            'Complete ground truth',[1 70]);
        if isempty(answer), break; end
        word=strtrim(string(answer{1}));
        if strlength(word)==0 || ~isempty(regexp(char(word),'\s','once'))
            errordlg('Use exactly one word.'); continue;
        end
        figure(fig); title(char('Draw box around '+word+'; DOUBLE-CLICK to accept.'));
        roi=drawrectangle('Color','green','Label',char(word)); wait(roi);
        if ~isvalid(roi), continue; end
        b=clamp_box(roi.Position,size(I));
        pending=[pending;table(id,0,b(1),b(2),b(3),b(4),word, ...
            'VariableNames',current.Properties.VariableNames)]; %#ok<AGROW>
    end
    if isgraphics(fig), close(fig); end
    choice=questdlg(['Have you labelled ALL readable words, checked tight boxes, ' ...
        'and agreed a consistent order? Review clipped/unreadable text policy before scoring.'], ...
        char(id),'Reviewed','Keep draft','Stop','Keep draft');
    if isempty(choice) || strcmp(choice,'Stop'), break; end
    if ~isempty(pending)
        order=reading_order(pending{:,{'x','y','width','height'}});
        pending=pending(order,:); pending.word_index=(1:height(pending))';
    end
    % Geometric ordering is only a default: edit CSV for rotated/mixed text order.
    gtAll=[gtAll(gtAll.image_id~=id,:);pending];
    images.has_text(k)=double(~isempty(pending));
    if strcmp(choice,'Reviewed'), images.annotation_status(k)="reviewed"; end
    writetable(gtAll,fullfile(cfg.DataDir,'ground_truth.csv'));
    writetable(images,fullfile(cfg.DataDir,'manifest.csv'));
end
fprintf('Saved annotation status. Verify word_index in the CSV for rotated layouts.\n');
end

function b=clamp_box(b,sz)
x=max(1,floor(b(1))); y=max(1,floor(b(2)));
right=min(sz(2)+1,ceil(b(1)+b(3))); bottom=min(sz(1)+1,ceil(b(2)+b(4)));
assert(right>x && bottom>y,'Invalid/outside-image box.');
b=[x y right-x bottom-y];
end

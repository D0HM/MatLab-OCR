function [images,gt] = load_dataset(cfg)
% LOAD_DATASET Validate annotations before any OCR work.
manifestPath = fullfile(cfg.DataDir,'manifest.csv');
gtPath = fullfile(cfg.DataDir,'ground_truth.csv');
assert(isfile(manifestPath) && isfile(gtPath),'SceneText:Dataset', ...
    'Dataset missing. Run label_dataset for real photos, or use start_demo.');
images = readtable(manifestPath,'TextType','string');
gt = readtable(gtPath,'TextType','string');
require_columns(images,{'image_id','filename','texture','split','source','has_text'});
if ~ismember('annotation_status',images.Properties.VariableNames)
    images.annotation_status = repmat("reviewed",height(images),1);
end
assert(all(ismember(images.annotation_status,["draft","reviewed"])), ...
    'SceneText:AnnotationStatus','Use draft/reviewed annotation_status.');
require_columns(gt,{'image_id','word_index','x','y','width','height','text'});
images.image_id = string(images.image_id); gt.image_id = string(gt.image_id);
gt.text = string(gt.text);
assert(height(images) > 0,'SceneText:EmptyDataset','No images in manifest.');
assert(numel(unique(images.image_id)) == height(images),'SceneText:IDs','Duplicate image_id.');
assert(all(ismember(images.texture,["simple","moderate","complex", ...
    "scene_sign","textured_glyph","mixed_layout"])), ...
    'SceneText:Texture','Unsupported texture label.');
assert(all(ismember(images.split,["dev","test","provided"])), ...
    'SceneText:Split','Use dev/test/provided split labels.');
assert(all(ismember(gt.image_id,images.image_id)),'SceneText:OrphanGT','Orphan GT image_id.');
assert(all(ismember(images.has_text,[0 1])),'SceneText:HasText','has_text must be 0 or 1.');
for k = 1:height(images)
    name = char(images.filename(k));
    assert(~contains(name,'..') && ~startsWith(name,filesep) ...
        && ~contains(name,':'),'SceneText:Filename','Use relative image filenames.');
    path = fullfile(cfg.DataDir,'images',name);
    assert(isfile(path),'SceneText:ImageMissing','Missing image: %s',path);
    I = read_image(path);
    rows = gt(gt.image_id == images.image_id(k),:);
    assert((height(rows)>0) == logical(images.has_text(k)), ...
        'SceneText:IncompleteGT','GT/has_text mismatch: %s',images.image_id(k));
    if isempty(rows), continue; end
    b = rows{:,{'x','y','width','height'}};
    assert(all(isfinite(b(:))) && all(b(:,1:2)>=1,'all') ...
        && all(b(:,3:4)>0,'all') && all(b(:,1)+b(:,3)<=size(I,2)+1) ...
        && all(b(:,2)+b(:,4)<=size(I,1)+1), ...
        'SceneText:Boxes','Invalid/out-of-bounds GT: %s',images.image_id(k));
    assert(all(~ismissing(rows.text) & strlength(strtrim(rows.text))>0) ...
        && all(cellfun(@isempty,regexp(cellstr(rows.text),'\s','once'))), ...
        'SceneText:WordGT','Label one nonempty WORD per bounding box.');
    assert(all(rows.word_index >= 1 & rows.word_index == floor(rows.word_index)) ...
        && numel(unique(rows.word_index)) == height(rows), ...
        'SceneText:WordIndex','Invalid/duplicate word_index.');
end
if cfg.Split ~= "all"
    images = images(images.split == cfg.Split,:);
end
assert(~isempty(images),'SceneText:NoSplit','No images for requested split: %s',cfg.Split);
gt = gt(ismember(gt.image_id,images.image_id),:);
end

function require_columns(t,names)
assert(all(ismember(names,t.Properties.VariableNames)), ...
    'SceneText:Schema','Required CSV columns: %s',strjoin(names,', '));
end

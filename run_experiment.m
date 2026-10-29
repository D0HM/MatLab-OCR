function outDir = run_experiment(cfg)
    %The core batch run. For every image and method (M0, F1, F2, plus F3 if you enable it) 
    % it preprocesses, runs OCR, and scores against the ground truth only if the annotations are reviewed. 
    % It writes ocr_results.csv (box, text, confidence), summary.csv, overlays, frequency spectrum images and a report into results/<timestamp>/.
    % RUN_EXPERIMENT Reproducible batch experiment. No GT is passed to prediction.
root = fileparts(mfilename('fullpath'));
addpath(root,fullfile(root,'src'));
if nargin < 1, cfg = project_config('provided'); end
check_requirements();
assert(ismember(cfg.Split,["all","dev","test","provided"]),'Invalid Split.');
assert(cfg.IoUThreshold>0 && cfg.IoUThreshold<=1,'Invalid IoUThreshold.');
[images,gtAll] = load_dataset(cfg);
if ~isfolder(cfg.OutputRoot), mkdir(cfg.OutputRoot); end
[~, token] = fileparts(tempname);
stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
outDir = fullfile(cfg.OutputRoot,[stamp '_' token]);
mkdir(outDir);
logID = fopen(fullfile(outDir,'run.log'),'w');
assert(logID >= 0,'Cannot write run.log');
logCleanup = onCleanup(@() fclose(logID)); %#ok<NASGU>
save(fullfile(outDir,'config.mat'),'cfg');
write_text(fullfile(outDir,'config.json'),jsonencode(cfg));
environment.MATLAB = version;
environment.Computer = computer;
environment.Toolboxes = ver;
write_text(fullfile(outDir,'environment.json'),jsonencode(environment));
writetable(images,fullfile(outDir,'manifest_used.csv'));
writetable(gtAll,fullfile(outDir,'ground_truth_used.csv'));
imageRecords = struct([]); allWords = table(); allOCR = table();
total = height(images)*numel(cfg.Methods)*numel(cfg.Detectors);
iteration = 0;
try
    for k = 1:height(images)
        id = images.image_id(k);
        I = read_image(fullfile(cfg.DataDir,'images',images.filename(k)));
        gt = sortrows(gtAll(gtAll.image_id==id,:),'word_index');
        for method = cfg.Methods
            for detector = cfg.Detectors
                if any(method==["F3","F4"]) && detector ~= cfg.Detectors(1), continue; end % F3/F4 ignore the detector
                iteration = iteration+1;
                fprintf('[%d/%d] %s | %s | %s\n',iteration,total,id,method,detector);
                fprintf(logID,'[%d/%d] %s | %s | %s\n',iteration,total,id,method,detector);
                imageTimer = tic;
                [P,stages] = preprocess_image(I,method,cfg);
                if method == "F3"
                    [pred,candidates] = predict_text_variants(I,cfg); mask = false(size(P,1),size(P,2));
                elseif method == "F4"
                    [pred,candidates] = predict_text_crops(I,cfg); mask = false(size(P,1),size(P,2));
                else
                    [pred,candidates,mask] = predict_text(P,detector,cfg,I);
                end
                elapsed = toc(imageTimer);
                annotationStatus = images.annotation_status(k);
                if cfg.RequireReviewedGT && annotationStatus == "draft"
                    [metrics,words] = unevaluated_metrics(gt,pred,candidates);
                else
                    [metrics,words] = evaluate_image(gt,pred,candidates,cfg);
                end
                row.ImageID = id;
                row.Texture = images.texture(k);
                row.Split = images.split(k);
                row.Source = images.source(k);
                row.Method = method;
                row.Detector = detector;
                row.Seconds = elapsed;
                row.AnnotationStatus = annotationStatus;
                row.Evaluated = ~(cfg.RequireReviewedGT && annotationStatus=="draft");
                fields = fieldnames(metrics);
                for f = 1:numel(fields), row.(fields{f}) = metrics.(fields{f}); end
                % First record supplies the fields for the struct array.
                if isempty(imageRecords)
                    imageRecords = row;
                else
                    imageRecords(end+1) = row; %#ok<AGROW>
                end
                if ~isempty(pred)
                    raw = addvars(pred,repmat(id,height(pred),1), ...
                        repmat(method,height(pred),1),repmat(detector,height(pred),1), ...
                        (1:height(pred))','Before',1,'NewVariableNames', ...
                        {'ImageID','Method','Detector','BoxIndex'});
                    if isempty(allOCR), allOCR=raw; else, allOCR=[allOCR;raw]; end %#ok<AGROW>
                    writetable(allOCR,fullfile(outDir,'ocr_results.csv'));
                end
                if ~isempty(words)
                    words = addvars(words,repmat(id,height(words),1), ...
                        repmat(method,height(words),1),repmat(detector,height(words),1), ...
                        'Before',1,'NewVariableNames',{'ImageID','Method','Detector'});
                    if isempty(allWords), allWords = words; else, allWords = [allWords;words]; end %#ok<AGROW>
                end
                % Filenames use ordinal image numbers: safe even for unusual IDs.
                dirName = sprintf('%03d_%s_%s',k,method,detector);
                sampleDir = fullfile(outDir,'images',dirName); mkdir(sampleDir);
                write_text(fullfile(sampleDir,'annotation_status.txt'),annotationStatus);
                imwrite(P,fullfile(sampleDir,'processed.png'));
                writetable(pred,fullfile(sampleDir,'predicted_words.csv'));
                writematrix(candidates,fullfile(sampleDir,'candidate_boxes.csv'));
                if cfg.SaveStages
                    names = fieldnames(stages);
                    for s = 1:numel(names)
                        imwrite(stages.(names{s}),fullfile(sampleDir,['stage_' names{s} '.png']));
                    end
                    if detector=="mser", imwrite(mask,fullfile(sampleDir,'mser_mask.png')); end
                end
                save_visuals(I,P,gt,pred,candidates,sampleDir,cfg);
                if any(startsWith(string(fieldnames(stages)),"fft_"))
                    save_frequency_visuals(stages,sampleDir,cfg);
                end
                % Checkpoint genuine completed rows; an exception still stops the run.
                writetable(struct2table(imageRecords),fullfile(outDir,'image_results.csv'));
            end
        end
    end
    results = struct2table(imageRecords);
    if isempty(allOCR)
        write_text(fullfile(outDir,'ocr_results.csv'), ...
            'ImageID,Method,Detector,BoxIndex,x,y,width,height,text,confidence');
    end
    if isempty(allWords)
        % A dataset of negative images may have no words at all.
        write_text(fullfile(outDir,'word_results.csv'), ...
            'ImageID,Method,Detector,WordIndex,Status,Expected,Recognized,Confidence,IoU,RecognitionRatePct,Exact');
    else
        writetable(allWords,fullfile(outDir,'word_results.csv'));
    end
    summary = summarize_results(results,cfg);
    writetable(summary,fullfile(outDir,'summary.csv'));
    if cfg.SaveFigures, plot_results(summary,outDir); end
    write_run_report(results,summary,outDir);
    fprintf(logID,'COMPLETE\n');
    fprintf('\nCompleted. Results: %s\n',outDir);
catch err
    fprintf(logID,'FAILED: %s\n',getReport(err,'extended','hyperlinks','off'));
    fprintf(2,'Run stopped. Partial results only: %s\n',outDir);
    rethrow(err);
end
end

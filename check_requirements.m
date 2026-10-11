function check_requirements()
% CHECK_REQUIREMENTS Fail early rather than produce fabricated/empty results.
if verLessThan('matlab', '9.9')
    error('SceneText:Version', 'MATLAB R2020b or newer is required.');
end
required = {'ocr', 'detectMSERFeatures', 'adapthisteq', 'imbinarize', ...
    'imclose', 'imopen', 'regionprops', 'insertObjectAnnotation'};
for k = 1:numel(required)
    if isempty(which(required{k}))
        error('SceneText:MissingToolbox', ...
            'Missing %s. Install Image Processing and Computer Vision Toolboxes.', required{k});
    end
end
fprintf('MATLAB %s | %s\n', version, computer);
end

function [P, stages] = preprocess_image(I, method, cfg)
% PREPROCESS_IMAGE Same image size and coordinates in all three methods.
% Required experiment: M0 original / F1 FFT lowpass / F2 three FFT stages.
% Legacy M1/M2 are optional ablations, not the Challenge02 core.
if ndims(I) == 3, G = rgb2gray(I); else, G = I; end
stages = struct('gray', G);
switch string(method)
    case "M0"
        P = I;
    case {"F1","F2"}
        [P,stages] = preprocess_frequency(G,method,cfg);
    case {"F3","F4"}
        % Display/diagnostic image only: OCR for F3 runs on fft_variants (see predict_text_variants).
        [P,stages] = preprocess_frequency(G,'F2',cfg);
    case "M1"
        P = adapthisteq(G, 'ClipLimit', cfg.CLAHEClipLimit);
        stages.enhanced = P;
    case "M2"
        S = medfilt2(G, cfg.MedianWindow, 'symmetric');
        se = strel('disk', cfg.BackgroundRadius, 0);
        polarity = cfg.Polarity;
        if strcmp(polarity, 'auto')
            border = [S(1,:), S(end,:), S(:,1)', S(:,end)'];
            if median(double(border)) >= 128
                polarity = 'dark';
            else
                polarity = 'bright';
            end
        end
        if strcmp(polarity, 'dark')
            % Closing estimates the bright background under dark strokes.
            signal = imbothat(S, se);
        elseif strcmp(polarity, 'bright')
            signal = imtophat(S, se);
        else
            error('SceneText:Polarity', 'Polarity must be auto, dark or bright.');
        end
        signal = imadjust(signal);
        BW = imbinarize(signal, 'adaptive', 'ForegroundPolarity', ...
            'bright', 'Sensitivity', cfg.AdaptiveSensitivity);
        BW = bwareaopen(BW, cfg.MinComponentArea);
        BW = imclose(BW, strel('rectangle', [1 2]));
        P = im2uint8(~BW); % OCR input: black text on white background.
        stages.smoothed = S;
        stages.morphology = signal;
        stages.mask = uint8(BW)*255;
        stages.processed = P;
    otherwise
        error('SceneText:Method', 'Unknown method: %s', method);
end
end

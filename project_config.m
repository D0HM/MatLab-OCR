function cfg = project_config(dataset)
% PROJECT_CONFIG Central experimental settings optimized for CPU and texture backgrounds.
if nargin < 1, dataset = 'provided'; end
root = fileparts(mfilename('fullpath'));
cfg.Root = root;
cfg.DataDir = fullfile(root, 'data', char(dataset));
cfg.OutputRoot = fullfile(root, 'results');
cfg.Methods = ["M0", "F1", "F2", "F3"]; 
cfg.Detectors = "ocr"; 
cfg.Split = "test"; 
cfg.Language = 'english';
% Run complementary OCR layouts: word recovers logo-like text; auto/block retain scenes.
cfg.OCRLayouts = {'auto','word','block'};
cfg.OCRLayout = 'auto'; % Backward-compatible fallback for saved configurations.
cfg.MinConfidence = 0.25; % Retained to capture raw box confidences before filtering[cite: 4]
cfg.IoUThreshold = 0.5;
cfg.CaseSensitive = false;
cfg.KeepPunctuation = true;
cfg.CLAHEClipLimit = 0.01;
cfg.MedianWindow = [3 3];
cfg.BackgroundRadius = 18;
cfg.Polarity = 'dark'; % Hardcoded from 'auto' to halve OCR processing time
cfg.AdaptiveSensitivity = 0.45;
cfg.MinComponentArea = 8;
cfg.MSERAreaRange = [20 12000];
cfg.MSERThresholdDelta = 3;
cfg.MinCharHeight = 8;
cfg.MaxCharHeightFraction = 0.6;
cfg.MinCharAspect = 0.05;
cfg.MaxCharAspect = 3.5;
cfg.WordJoinPixels = 7;
cfg.ROIPadding = 4;
cfg.MinCandidateWidth = 8;
cfg.MinCandidateHeight = 8;
cfg.SaveFigures = true;
cfg.SaveStages = true;

% Frequency-domain core (minimum 50% workload requirement)[cite: 4]
cfg.FFTPadFraction = 0.15;
cfg.GaussianCutoff = 0.065;
cfg.HomomorphicCutoff = 0.025;
cfg.HomomorphicLowGain = 0.6;
cfg.HomomorphicHighGain = 1.2;
cfg.HighBoostCutoff = 0.04;
cfg.HighBoostAmount = 0.3;
cfg.MinConfidence = 0.2;

% F3 = multi-variant frequency-domain OCR: low-pass and F2-style FFT pipelines.
% Runtime is |channels|*|pipelines|*|sigmas|*|scales|*|layouts| OCR calls/image.
cfg.F3Channels = {'gray','sat','val','bgdist'}; % bgdist = colour distance from border colour
cfg.F3Pipelines = {'lowpass','homomorphic_highboost'};
cfg.F3Notch = false;                 % Enable only for known periodic texture; it doubles runtime.
cfg.F3NotchPeaks = 4; cfg.F3NotchSigma = 1.5; cfg.F3NotchMinRes = 0.8; cfg.F3NotchMinFreq = 0.015;
cfg.F3Sigmas = [0.04 0.065 0.09];
cfg.F3Scales = [0.75 1.00];          % Avoid former 6-60%% scales that remove character detail.
cfg.F3Invert = false;
cfg.F3Border = 0; % A white frame changed dark textured-word recognition; enable only if an image touches its edge.
cfg.F3Layouts = {'auto','word'};
cfg.F3Layout = 'auto'; % Backward-compatible fallback for saved configurations.
cfg.F3MinConfidence = 0.30; % OCR confidence 0..1
cfg.F3MinChars = 2;
cfg.F3NMSIoU = 0.30;
cfg.F3MinVotes = 1; % Keep a valid read from one complementary frequency/layout variant.
cfg.RequireReviewedGT = true;
end

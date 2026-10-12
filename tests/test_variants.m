function tests=test_variants
tests=functiontests(localfunctions);
end

function cfg=smallcfg()
cfg=project_config();
cfg.F3Channels={'gray'}; cfg.F3Sigmas=0.02; cfg.F3Scales=[0.5 0.25]; cfg.F3Notch=false;
cfg.F3Pipelines={'lowpass'}; cfg.F3Layouts={'auto'};
cfg.F3Border=20;
end

function testVariantCountAndBorder(t)
cfg=smallcfg(); I=uint8(255*rand(80,120,3)); V=fft_variants(I,cfg);
verifyEqual(t,numel(V),2);
verifyEqual(t,size(V(1).image),[40+2*cfg.F3Border, 60+2*cfg.F3Border]);
verifyEqual(t,V(1).image(1,1),uint8(255));
end

function testBoxMapsBackToOriginal(t)
cfg=smallcfg(); cfg.F3Scales=0.5; cfg.F3MinVotes=1; I=uint8(255*rand(80,120,3));
b=cfg.F3Border; fake=@(img,varargin) struct('Words',"ABC",'WordBoundingBoxes',[b+10 b+5 20 10],'WordConfidences',0.9);
[boxes,words]=ocr_variants_core(I,cfg,fake);
verifyEqual(t,boxes,[(10-1)/0.5+1, (5-1)/0.5+1, 40, 20],'AbsTol',1e-9);
verifyEqual(t,words,{'ABC'});
end

function testNoiseFilteredAndMerged(t)
cfg=smallcfg(); cfg.F3Scales=0.5; cfg.F3Invert=true; cfg.F3MinVotes=2; I=uint8(255*rand(80,120,3)); b=cfg.F3Border;
fake=@(img,varargin) struct('Words',["FUR";"x";"q?"],'WordBoundingBoxes',[b+5 b+5 20 10; b+30 b+5 8 8; b+40 b+20 9 9], ...
    'WordConfidences',[0.9;0.9;0.1]);
[~,words]=ocr_variants_core(I,cfg,fake);
verifyEqual(t,words,{'FUR'}); % single char and low-confidence dropped; duplicates merged
end

function testNotchAndColourChannels(t)
cfg=smallcfg(); cfg.F3Channels={'gray','bgdist'}; cfg.F3Notch=[false true]; cfg.F3Scales=0.5;
[x,~]=meshgrid(1:120,1:80); I=repmat(uint8(127+100*sin(2*pi*x/8)),[1 1 3]);
V=fft_variants(I,cfg);
verifyEqual(t,numel(V),4); % 2 channels x notch off/on
verifyTrue(t,any(strcmp({V.name},'bgdist_notch_lowpass_sig0.020_s0.50')));
end

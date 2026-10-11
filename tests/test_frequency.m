function tests=test_frequency
tests=functiontests(localfunctions);
end

function testLowpassDC(t)
cfg=project_config();
for sz={[15 18],[16 17]}
    A=ones(sz{1})*0.4;
    [B,~]=fft_domain_filter(A,'lowpass',cfg);
    verifyEqual(t,B,A,'AbsTol',1e-12);
end
end

function testHighboostDC(t)
cfg=project_config(); A=ones(12,13)*0.7;
[B,~]=fft_domain_filter(A,'highboost',cfg);
verifyEqual(t,B,A,'AbsTol',1e-12);
end

function testHomomorphicDC(t)
cfg=project_config(); A=ones(19,20)*(-0.8);
[B,~]=fft_domain_filter(A,'homomorphic',cfg);
verifyEqual(t,B,A*cfg.HomomorphicLowGain,'AbsTol',1e-12);
end

function testLowpassAttenuates(t)
cfg=project_config(); [x,~]=meshgrid(0:63,0:63);
A=sin(2*pi*0.25*x);
[B,~]=fft_domain_filter(A,'lowpass',cfg);
verifyLessThan(t,std(B(:)),0.01*std(A(:)));
end

function testDraftGTNotScored(t)
gt=table("a",1,1,1,20,20,"TEXT",'VariableNames', ...
    {'image_id','word_index','x','y','width','height','text'});
p=table(1,1,20,20,"TEXT",0.9,'VariableNames', ...
    {'x','y','width','height','text','confidence'});
[m,w]=unevaluated_metrics(gt,p,p{:,1:4});
verifyTrue(t,isnan(m.CER)); verifyTrue(t,isnan(m.RecognitionRatePct));
verifyEqual(t,m.AvgConfidence,0.9); verifyEqual(t,height(w),0);
end

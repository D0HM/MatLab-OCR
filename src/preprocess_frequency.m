function [P,stages] = preprocess_frequency(G,method,cfg)
% PREPROCESS_FREQUENCY Required core for Challenge02.
% F1: Gaussian frequency lowpass to attenuate high-frequency glyph texture.
% F2: log-domain illumination filter -> Gaussian texture filter -> highboost.
% All three F2 filters explicitly construct H(u,v) and multiply FFT spectra.
A=im2double(G);
pad=max(8,round(min(size(A))*cfg.FFTPadFraction));
A=padarray(A,[pad pad],'symmetric','both');
stages=struct('gray',G);
if string(method)=="F2"
    logA=log(max(A,1/255));
    [logB,d]=fft_domain_filter(logA,'homomorphic',cfg);
    A=exp(logB); % Return from multiplicative illumination model to intensity.
    stages=append_debug(stages,d,'fft_illumination');
    stages.illumination_result=crop_display(A,pad);
end
[A,d]=fft_domain_filter(A,'lowpass',cfg);
stages=append_debug(stages,d,'fft_texture');
stages.texture_result=crop_display(A,pad);
if string(method)=="F2"
    [A,d]=fft_domain_filter(A,'highboost',cfg);
    stages=append_debug(stages,d,'fft_highboost');
    stages.highboost_result=crop_display(A,pad);
end
A=A(pad+1:end-pad,pad+1:end-pad);
% Stretch output contrast only after the frequency-domain reconstruction.
if max(A(:))-min(A(:))<eps
    P=im2uint8(min(1,max(0,A)));
else
    P=display_u8(A);
end
stages.processed=P;
end

function stages=append_debug(stages,d,prefix)
names=fieldnames(d);
for k=1:numel(names), stages.([prefix '_' names{k}])=d.(names{k}); end
end

function V=crop_display(A,pad)
V=display_u8(A(pad+1:end-pad,pad+1:end-pad));
end

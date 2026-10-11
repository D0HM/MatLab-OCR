function [B,debug] = fft_domain_filter(A,kind,cfg)
% FFT_DOMAIN_FILTER Explicit centered 2-D DFT -> transfer function -> IDFT.
% No spatial convolution substitutes for the frequency-domain operation.
A=double(A); [rows,cols]=size(A);
u=(-floor(cols/2):ceil(cols/2)-1)/cols;
v=(-floor(rows/2):ceil(rows/2)-1)/rows;
[U,V]=meshgrid(u,v); radius2=U.^2+V.^2;
switch string(kind)
    case "lowpass"
        assert(cfg.GaussianCutoff>0,'GaussianCutoff must be positive.');
        H=exp(-radius2/(2*cfg.GaussianCutoff^2));
    case "homomorphic"
        assert(cfg.HomomorphicCutoff>0,'HomomorphicCutoff must be positive.');
        assert(cfg.HomomorphicLowGain>0 && cfg.HomomorphicHighGain>0, ...
            'Homomorphic gains must be positive.');
        low=exp(-radius2/(2*cfg.HomomorphicCutoff^2));
        H=cfg.HomomorphicLowGain+(cfg.HomomorphicHighGain ...
            -cfg.HomomorphicLowGain)*(1-low);
    case "highboost"
        assert(cfg.HighBoostCutoff>0 && cfg.HighBoostAmount>=0, ...
            'Invalid highboost settings.');
        low=exp(-radius2/(2*cfg.HighBoostCutoff^2));
        H=1+cfg.HighBoostAmount*(1-low);
    otherwise
        error('SceneText:FFTKind','Unknown frequency filter: %s',kind);
end
F=fftshift(fft2(A));
filteredF=F.*H;
inverse=ifft2(ifftshift(filteredF));
residual=max(abs(imag(inverse(:))));
assert(residual <= 1e-8*max(1,max(abs(inverse(:)))), ...
    'SceneText:FFTSymmetry','Unexpected imaginary residual in inverse FFT.');
B=real(inverse);
debug.spectrum=display_u8(log1p(abs(F)));
debug.transfer=uint8(255*H/max(H(:)));
debug.filtered_spectrum=display_u8(log1p(abs(filteredF)));
debug.reconstructed=display_u8(B);
end

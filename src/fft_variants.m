function V = fft_variants(I, cfg)
% FFT_VARIANTS Build OCR input candidates for method F3 (frequency-domain core).
% For each channel x notch(on/off) x Gaussian cutoff x downscale:
%   symmetric pad -> [FFT notch: remove periodic texture peaks] -> FFT lowpass -> crop
%   -> area downscale -> dark-text-on-light polarity -> white border.
% Channels: gray | sat (saturation) | val (max RGB) | bgdist (colour distance from the
% image-border colour; text/object bright, so it is inverted to dark-on-light).
% Base MATLAB only (no Image Processing Toolbox). Returns struct array:
%   image (uint8 OCR input), sx, sy (scale), border (px), name (char).
if isinteger(I), I = double(I)/double(intmax(class(I))); else, I = double(I); end
names = {}; data = {}; flip = [];
if ndims(I) == 3
    mx = max(I,[],3); mn = min(I,[],3);
    names = {'gray','sat','val','bgdist'};
    data = {0.2989360213*I(:,:,1)+0.5870430745*I(:,:,2)+0.1140209043*I(:,:,3), ...
            (mx-mn)./max(mx,eps), mx, bg_distance(I)};
    flip = [false false false true];
else
    names = {'gray'}; data = {I}; flip = false;
end
notchModes = getf(cfg,'F3Notch',false);
b = cfg.F3Border;
V = struct('image',{},'sx',{},'sy',{},'border',{},'name',{});
for c = 1:numel(cfg.F3Channels)
    k = find(strcmp(names, char(cfg.F3Channels{c})), 1);
    if isempty(k), continue; end
    A0 = data{k};
    pad = max(8, round(min(size(A0))*cfg.FFTPadFraction));
    Ap = sym_pad(A0, pad);
    for nm = notchModes(:)'
        A = Ap; tag = '';
        if nm, A = notch_suppress(Ap, cfg); tag = '_notch'; end
        for sig = cfg.F3Sigmas(:)'
            c2 = cfg; c2.GaussianCutoff = sig;
            [B, ~] = fft_domain_filter(A, 'lowpass', c2);
            B = B(pad+1:end-pad, pad+1:end-pad);
            for s = cfg.F3Scales(:)'
                [h, w] = size(B);
                h2 = max(8, round(h*s)); w2 = max(8, round(w*s));
                sx = w2/w; sy = h2/h;
                U = display_u8(area_resize(B, h2, w2));
                if flip(k), U = 255 - U; end
                U = [255*ones(b, w2+2*b, 'uint8'); ...
                     255*ones(h2, b, 'uint8'), U, 255*ones(h2, b, 'uint8'); ...
                     255*ones(b, w2+2*b, 'uint8')];
                nmx = sprintf('%s%s_sig%.3f_s%.2f', names{k}, tag, sig, s);
                V(end+1) = struct('image', U, 'sx', sx, 'sy', sy, 'border', b, 'name', nmx); %#ok<AGROW>
                if cfg.F3Invert
                    V(end+1) = struct('image', 255-U, 'sx', sx, 'sy', sy, 'border', b, 'name', [nmx '_inv']); %#ok<AGROW>
                end
            end
        end
    end
end
end

function v = getf(cfg, name, default)
if isfield(cfg, name), v = cfg.(name); else, v = default; end
end

function D = bg_distance(I)
% Euclidean RGB distance from the median colour of the outer 5% border band.
[h, w, ~] = size(I); t = max(2, round(0.05*min(h,w)));
m = false(h, w); m(1:t,:) = true; m(end-t+1:end,:) = true; m(:,1:t) = true; m(:,end-t+1:end) = true;
bg = zeros(1,1,3);
for k = 1:3, ch = I(:,:,k); bg(1,1,k) = median(ch(m)); end
D = sqrt(sum((I - repmat(bg,[h w 1])).^2, 3));
end

function B = notch_suppress(A, cfg)
% Automatic notch: find the strongest periodic peaks of the log-spectrum (after removing the
% radial mean profile) and attenuate each peak and its mirror with a Gaussian notch.
nPeaks = getf(cfg,'F3NotchPeaks',4); sg = getf(cfg,'F3NotchSigma',1.5);
minRes = getf(cfg,'F3NotchMinRes',0.8); minF = getf(cfg,'F3NotchMinFreq',0.015);
[r, c] = size(A);
F = fftshift(fft2(A)); M = log(1+abs(F));
[U, V] = meshgrid((-floor(c/2):ceil(c/2)-1)/c, (-floor(r/2):ceil(r/2)-1)/r);
R = sqrt(U.^2+V.^2); idx = floor(R/0.005)+1;
prof = accumarray(idx(:), M(:)) ./ max(accumarray(idx(:), 1), 1);
Res = M - prof(idx); Res(R < minF | R > 0.45) = -inf;
cy = floor(r/2)+1; cx = floor(c/2)+1; H = ones(r, c);
for k = 1:nPeaks
    [v, i] = max(Res(:)); if v < minRes, break; end
    [iy, ix] = ind2sub([r c], i);
    for p = [iy ix; 2*cy-iy 2*cx-ix]'
        d2 = (U-U(1,p(2))).^2 + (V-V(p(1),1)).^2;
        H = H .* (1 - exp(-d2/(2*(sg/min(r,c))^2)));
    end
    win = (abs((1:r)'-iy) <= 6) * (abs((1:c)-ix) <= 6);  Res(win > 0) = -inf;
    win = (abs((1:r)'-(2*cy-iy)) <= 6) * (abs((1:c)-(2*cx-ix)) <= 6); Res(win > 0) = -inf;
end
B = real(ifft2(ifftshift(F .* H)));
end

function A = sym_pad(A, pad)
r = [pad:-1:1, 1:size(A,1), size(A,1):-1:size(A,1)-pad+1];
c = [pad:-1:1, 1:size(A,2), size(A,2):-1:size(A,2)-pad+1];
A = A(r, c);
end

function B = area_resize(A, h2, w2)
% Box-average (area) resize with base MATLAB only; avoids aliasing at 0.1x.
B = area_1d(area_1d(A, h2).', w2).';
end

function B = area_1d(A, n2)
n = size(A,1); edges = linspace(0, n, n2+1);
C = [zeros(1,size(A,2)); cumsum(A,1)];
Ce = interp1(0:n, C, edges(:), 'linear');
B = diff(Ce,1,1) ./ diff(edges(:));
end
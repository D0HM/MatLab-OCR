function [theta, strength] = estimate_text_angle(G)
% ESTIMATE_TEXT_ANGLE FFT-based tilt of text lines in a crop, in degrees within (-45,45].
% Text strokes put spectral energy along two perpendicular axes; the circular mean of 4*angle over a
% mid-frequency band gives that axis direction (mod 90). theta > 0 means the text is rotated
% counter-clockwise on screen (the convention of rotate_image); deskew with rotate_image(G,-theta).
% strength (0..1) is how peaked the spectrum is; low values mean the estimate is unreliable.
G = double(G); if ndims(G) == 3, G = 0.2989*G(:,:,1)+0.5870*G(:,:,2)+0.1140*G(:,:,3); end
k = ceil(max(size(G))/192);
if k > 1
    h = floor(size(G,1)/k)*k; w = floor(size(G,2)/k)*k; G = G(1:h,1:w);
    G = squeeze(mean(reshape(G, k, h/k, w), 1));      % (h/k) x w
    G = squeeze(mean(reshape(G', k, w/k, h/k), 1))';  % (h/k) x (w/k)
end
[h, w] = size(G); G = G - mean(G(:));
wy = 0.5-0.5*cos(2*pi*(0:h-1)'/max(h-1,1)); wx = 0.5-0.5*cos(2*pi*(0:w-1)/max(w-1,1));
N = 256; F = fftshift(fft2(G.*(wy*wx), N, N)); P = abs(F);
[U, V] = meshgrid((-N/2:N/2-1)/N); R = sqrt(U.^2+V.^2); band = R >= 0.03 & R <= 0.35;
ang = atan2(V(band), U(band)); p = P(band);
Z = sum(p.*exp(1i*4*ang)); theta = -angle(Z)/4*180/pi; strength = abs(Z)/max(sum(p), eps);
end

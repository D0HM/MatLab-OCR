function V = display_u8(A)
% DISPLAY_U8 Map finite arrays to [0,255] for diagnostics, not quantitative FFT.
A=double(A); lo=min(A(:)); hi=max(A(:));
if hi-lo <= eps(max(1,abs(hi)))
    V=uint8(zeros(size(A)));
else
    V=uint8(255*(A-lo)/(hi-lo));
end
end

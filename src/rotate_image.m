function [R, M] = rotate_image(A, theta, fill)
% ROTATE_IMAGE Rotate counter-clockwise (as seen on screen) by theta degrees about the centre.
% The canvas grows to hold the whole image; empty corners get 'fill'. Base MATLAB only (interp2).
% M holds what rotate_points_back needs to map rotated-image points to the original image.
cls = class(A); D = double(A); [h, w, nc] = size(D);
t = theta*pi/180; ct = cos(t); st = sin(t);
w2 = ceil(abs(w*ct)+abs(h*st)); h2 = ceil(abs(w*st)+abs(h*ct));
[X, Y] = meshgrid(1:w2, 1:h2); xc = (w2+1)/2; yc = (h2+1)/2; dx = X-xc; dy = Y-yc;
xs = (w+1)/2 + ct*dx - st*dy; ys = (h+1)/2 + st*dx + ct*dy;
R = zeros(h2, w2, nc);
for k = 1:nc, R(:,:,k) = interp2(D(:,:,k), xs, ys, 'linear', fill); end
if strcmp(cls,'uint8'), R = uint8(min(255,max(0,R))); end
M = struct('w',w,'h',h,'w2',w2,'h2',h2,'ct',ct,'st',st);
end

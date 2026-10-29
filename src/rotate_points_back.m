function B = rotate_points_back(boxes, M)
% ROTATE_POINTS_BACK Map [x y w h] boxes found in a rotate_image result back to the original image
% (axis-aligned bounding box of the four rotated-back corners).
B = zeros(size(boxes));
xc = (M.w2+1)/2; yc = (M.h2+1)/2;
for i = 1:size(boxes,1)
    b = boxes(i,:); cx = [b(1) b(1)+b(3) b(1) b(1)+b(3)]; cy = [b(2) b(2) b(2)+b(4) b(2)+b(4)];
    ox = (M.w+1)/2 + M.ct*(cx-xc) - M.st*(cy-yc); oy = (M.h+1)/2 + M.st*(cx-xc) + M.ct*(cy-yc);
    B(i,:) = [min(ox) min(oy) max(ox)-min(ox) max(oy)-min(oy)];
end
end

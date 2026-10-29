function tests = test_deskew
tests = functiontests(localfunctions);
end

function img = barimage()
img = 255*ones(160,320,'uint8');
for r = [30 80 130], for c = 20:40:280, img(r-8:r+8, c:c+25) = 0; end, end   % rows of text-like blocks
end

function testAngleEstimateAndSign(t)
img = barimage();
for a = [-20 0 15]
    est = estimate_text_angle(rotate_image(img, a, 255));
    verifyEqual(t, est, a, 'AbsTol', 3);
end
end

function testPointsMapBack(t)
img = 255*ones(100,200,'uint8'); img(40:60, 150:170) = 0;          % dark square, centre (160,50)
[R, M] = rotate_image(img, 25, 255);
[y, x] = find(R < 128); box = [min(x) min(y) max(x)-min(x)+1 max(y)-min(y)+1];
b = rotate_points_back(box, M); c = [b(1)+b(3)/2, b(2)+b(4)/2];
verifyEqual(t, c, [160 50], 'AbsTol', 3);
end

function testDeskewCoreRunsWithFakeOcr(t)
img = barimage(); R = rotate_image(img, 20, 255);
fake = @(im,layout) struct('Words',"AB",'WordBoundingBoxes',[15 15 20 10],'WordConfidences',0.9);
[boxes, words] = ocr_deskew_core(R, struct('CraftLayouts',{{'word'}}), fake);
verifyTrue(t, ~isempty(words)); verifyEqual(t, size(boxes,2), 4)
end

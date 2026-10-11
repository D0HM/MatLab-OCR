function I = read_image(path)
% READ_IMAGE Support grayscale, RGB, indexed PNG and transparency.
[A, map, alpha] = imread(path);
if ~isempty(map), A = ind2rgb(A, map); end
I = im2uint8(A);
if ~isempty(alpha)
    a = im2double(alpha);
    I = uint8(double(I).*a + 255*(1-a));
end
if ndims(I) == 3 && size(I,3) ~= 3
    error('SceneText:Channels', 'Expected one or three image channels: %s', path);
end
end

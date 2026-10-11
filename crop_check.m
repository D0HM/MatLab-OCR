I  = imread('data/provided/images/TextureText04.jpg');   % change to the image you test
gt = readtable('data/provided/ground_truth.csv','TextType','string');
g  = gt(gt.image_id=="TextureText04",:);                 % must match the image above
m = 30;
for k = 1:height(g)
    y = max(1,g.y(k)-m):min(size(I,1),g.y(k)+g.height(k)-1+m);
    x = max(1,g.x(k)-m):min(size(I,2),g.x(k)+g.width(k)-1+m);
    imwrite(I(y,x,:), 'crop_tmp.png');
    fprintf('\nGT: %s\n', g.text(k));
    for cut = [0.03 0.065]
        for sc = [0.25 0.5 1]
            fprintf('cutoff=%.3f scale=%.2f -> ', cut, sc);
            ocr_one('crop_tmp.png','Method','F1','Cutoff',cut,'Scale',sc,'Show',false);
        end
    end
end
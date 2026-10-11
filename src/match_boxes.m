function [pairs, ious] = match_boxes(gt, pred, threshold)
% MATCH_BOXES One-to-one MAXIMUM-CARDINALITY matching at fixed IoU threshold.
% Augmenting paths avoid the undercount possible in greedy IoU matching.
% Descending-IoU neighbor order is a tie preference, not optimal total IoU.
n = size(gt,1); m = size(pred,1);
ious = zeros(n,m);
for g = 1:n
    for p = 1:m
        lo = max(gt(g,1:2), pred(p,1:2));
        hi = min(gt(g,1:2)+gt(g,3:4),pred(p,1:2)+pred(p,3:4));
        sz = max(0,hi-lo);
        inter = prod(sz);
        uni = prod(gt(g,3:4))+prod(pred(p,3:4))-inter;
        ious(g,p) = inter/max(uni,eps);
    end
end
owner = zeros(1,m);
for g = 1:n
    seen = false(1,m);
    augment(g);
end
ps = reshape(find(owner > 0), 1, []);
pairs = [owner(ps)', ps'];
if ~isempty(pairs), pairs = sortrows(pairs,1); end

    function ok = augment(g)
        ok = false;
        choices = find(ious(g,:) >= threshold);
        [~, priority] = sort(ious(g,choices),'descend');
        for p = choices(priority)
            if seen(p), continue; end
            seen(p) = true;
            if owner(p) == 0 || augment(owner(p))
                owner(p) = g;
                ok = true;
                return;
            end
        end
    end
end

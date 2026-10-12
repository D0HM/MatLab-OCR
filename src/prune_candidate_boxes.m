function boxes = prune_candidate_boxes(boxes, imageSize, cfg)
% PRUNE_CANDIDATE_BOXES Removes implausibly large and nested MSER text proposals.
% A contained fragment is not a separate word region, so retain the larger proposal.
if isempty(boxes), return; end
area = boxes(:,3).*boxes(:,4);
keep = area <= cfg.MaxCandidateAreaFraction*imageSize(1)*imageSize(2);
boxes = boxes(keep,:); area = area(keep);
[~, order] = sort(area, 'descend'); kept = zeros(0,1);
for i = order(:)'
    nested = false;
    for j = kept(:)'
        if intersection_over_smaller(boxes(i,:), boxes(j,:)) >= cfg.CandidateContainment
            nested = true; break;
        end
    end
    if ~nested, kept(end+1) = i; end %#ok<AGROW>
end
boxes = boxes(kept,:);
if size(boxes,1) > cfg.MaxCandidateBoxes
    areas = boxes(:,3).*boxes(:,4); [~, ix] = sort(areas,'descend'); boxes = boxes(ix(1:cfg.MaxCandidateBoxes),:);
end
if ~isempty(boxes), boxes = boxes(reading_order(boxes),:); end
end

function value = intersection_over_smaller(a, b)
% INTERSECTION_OVER_SMALLER Measures whether either region is almost fully inside the other.
x1=max(a(1),b(1)); y1=max(a(2),b(2));
x2=min(a(1)+a(3),b(1)+b(3)); y2=min(a(2)+a(4),b(2)+b(4));
intersection=max(0,x2-x1)*max(0,y2-y1);
value=intersection/max(min(a(3)*a(4),b(3)*b(4)),eps);
end

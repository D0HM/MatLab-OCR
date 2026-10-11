function order = reading_order(boxes)
% READING_ORDER Approximate horizontal lines, then sort each line left-right.
% Scope excludes vertical/curved text and heavily rotated photographs.
if isempty(boxes), order = zeros(0,1); return; end
[~, remaining] = sort(boxes(:,2)+boxes(:,4)/2);
order = zeros(0,1);
while ~isempty(remaining)
    first = remaining(1);
    center = boxes(:,2)+boxes(:,4)/2;
    same = abs(center(remaining)-center(first)) <= ...
        0.5*min(boxes(remaining,4),boxes(first,4));
    line = remaining(same);
    [~, left] = sort(boxes(line,1));
    order = [order; line(left)]; %#ok<AGROW>
    remaining(same) = [];
end
end

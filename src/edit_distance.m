function d = edit_distance(a,b)
% EDIT_DISTANCE Levenshtein distance on characters OR arrays of word tokens.
% Space-efficient dynamic programming; insertions/substitutions/deletions cost 1.
a = a(:); b = b(:);
previous = 0:numel(b);
for i = 1:numel(a)
    current = zeros(1,numel(b)+1);
    current(1) = i;
    for j = 1:numel(b)
        current(j+1) = min([current(j)+1, previous(j+1)+1, ...
            previous(j)+double(~isequal(a(i),b(j)))]);
    end
    previous = current;
end
d = previous(end);
end

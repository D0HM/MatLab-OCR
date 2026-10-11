function write_text(path,text)
% WRITE_TEXT Use UTF-8 for Thai instructions and machine-readable reports.
fid = fopen(path,'w','n','UTF-8');
assert(fid>=0,'SceneText:Write','Cannot write: %s',path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',text);
end

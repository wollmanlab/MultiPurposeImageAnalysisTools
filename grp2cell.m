function [cl,unqid,avg]=grp2cell(M,id,func)
% function [cl,unqid,avg]=grp2cell(M,id,func)
% transform a grouped variable into cell array
% id must be numeric M a vector or a matrix
%
% as a "bonus" if nargout==3 it calcualtes the mean of ALL the elements in
% each cell (regardless is M is a ector aor a matrix!!! basically runs:
% f=@(x) mean(x(:))


if size(id,2)~=1, error('id must be a colum vector)'); end
if size(M,1)~=size(id,1), error('id must have same number of rows as M'); end

% remove id==0 if needed
if any(id==0)
    M=M(id>0,:);
    id=id(id>0);
end

if nargin==2;
    func=@(x) mean(x(:));
end

% % for the median case - use the fact that id is integer and add the rest as
% % a decimal for sorting. this will result in an approximage "sortrows"
% % where each groupd in internaly sorted
% if ischar(func) && strcmp(func,'approxmedian') && size(M,2)==1
%     addon=0.9*(M/max(M));
%     addon(isnan(M))=0.95;
%     id=double(id)+addon;
%     MareNotNaNs=~isnan(M);
% end



% % floor if to retun it to the regular mode. 
% if ischar(func) && strcmp(func,'approxmedian') && size(M,2)==1
%     id=floor(id);
%     MareNotNaNs=MareNotNaNs(ordr);
% end
idold=id; 
[id,ordr]=sort(id);
unqid=unique(id);
n=length(unqid);

if ~isequal(idold,id)
    M=M(ordr,:);
end
df=diff(id);
df=find(df);
df=[0; df; length(id)];
cl=cell(n,1);
if size(M,2)==1 && exist('grp2cell_indxloop','file')==3 && nargin==2
    if nargout==3 
        [cl,avg]=grp2cell_indxloop(double(M),df);
    else
        cl=grp2cell_indxloop(double(M),df);
    end
% elseif ischar(func) && strcmp(func,'approxmedian') && size(M,2)==1 && exist('grp2cell_indxloop','file')==3
%     avg=zeros(length(cl),1);
%     cl=grp2cell_indxloop(double(M),df);
%     [~,prcntNotNan]=grp2cell_indxloop(double(MareNotNaNs),df);
%     md_ix = ceil((df(2:end)-df(1:end-1)).*prcntNotNan);
%     for i=1:n
%         avg(i)=cl{i}(md_ix(i));
%     end
else
    for i=1:n
        cl{i}=M((df(i)+1):df(i+1),:);
    end
    if nargout==3
        avg=cellfun(func,cl);
    end
end
    
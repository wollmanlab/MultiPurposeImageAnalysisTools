function lbl=labelcellswithnuc(bw,nuclbl)
% this function labels a mask based on a combination of "traditional"
% bwlabel and splitting large multinuclei cells into parts. 

%% create "accessory" variabel for finding xy centers
[X,Y]=meshgrid(1:size(bw,2),1:size(bw,1));

%% start with traditional labelsing
lbl=bwlabel(bw,4);

%% clean up any forground pixels that doesn't have a nuc in it
nuccell=grp2cell(lbl(:),nuclbl(:));
nuccell=setdiff(cat(1,nuccell{:}),0);
bw=ismember(lbl,nuccell);
lbl=bwlabel(bw,4);

%% find if there are multinuclei cells that I want to split
celltosplit=find(cellfun(@(x) length(unique(x))>2,grp2cell(nuclbl(:),lbl(:))));
tosplit=bw; % init with mask
tosplit(~ismember(lbl,celltosplit))=false;
    
%% split cells using ann 
tosplitlbl=bwlabel(tosplit);
if max(tosplit(:))==0
    lbl=bwlabel(bw);
    return
end
[nucid,spotid]=grp2cell(nuclbl(:),tosplitlbl(:));
nucid=cellfun(@(x) setdiff(x,0),nucid,'uniformoutput',0);
nnuc=max(cellfun(@length,nucid));
% nucid now has the allowed nucids for each spot

[r,c,sid]=find(tosplitlbl);
nuctmplbl=nuclbl;% & tosplit;
nuctmplbl(~tosplit)=0;
% nuctmplbl=bwlabel(nuctmp,4);
[Xpnt,xid,x]=grp2cell(X(:),nuctmplbl(:));
[Ypnt,~,y]=grp2cell(Y(:),nuctmplbl(:));

for i=1:length(Xpnt)
    otherPnt=[cat(1,Xpnt{setdiff(1:length(Xpnt),i)}) cat(1,Ypnt{setdiff(1:length(Ypnt),i)})];
    nnidx = annquery([Xpnt{i} Ypnt{i}]',otherPnt', 1);
    tbl=tabulate(double(nnidx'));
    [~,mx]=max(tbl(:,2));
    xref(i)=Xpnt{i}(tbl(mx,1));
    yref(i)=Ypnt{i}(tbl(mx,1));
end
    
    
id=annquery([xref; yref],[c(:) r(:)]',nnuc);


id=xid(id);
idunq=zeros(1,size(id,2));

for i=1:length(spotid)
    [~,mi]=max(ismember(id(:,sid==spotid(i)),nucid{i}));
    idunq(sid==spotid(i))=id(sub2ind(size(id),mi(:),find(sid==spotid(i))));
end
lbl2=zeros(size(bw));
lbl2(sub2ind(size(bw),r,c))=idunq;
    
%% combine the two lbl matrices - keep booking ok
lbl=bwlabel(bw & ~ tosplit,4);
lbl(lbl>0)=lbl(lbl>0)+max(lbl2(:));
lbl(lbl2>0)=lbl2(lbl2>0);

%% seperate the labels & relabel
lbl=seperateLbl(lbl);
lbl=bwlabel(lbl>0);

%% clean up any forground pixels that doesn't have a nuc in it
nuccell=grp2cell(lbl(:),nuclbl(:));
nuccell=setdiff(cat(1,nuccell{:}),0);
bw=ismember(lbl,nuccell);
lbl=bwlabel(bw);


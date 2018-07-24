function [lbl,nuclbl]=labelcellswithnucUsingANN(bw,nuclbl)
% this function labels a mask based on a combination of "traditional"
% bwlabel and splitting large multinuclei cells into parts with watershed 
% & distane transform of nuc. 


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
nottosplit = bw; 
nottosplit(ismember(lbl,celltosplit)) = false;

%% split cells using watershed
[tosplitlbl,n]=bwlabel(tosplit);
if max(tosplit(:))==0
    lbl=bwlabel(bw);
    return
end

[y,x]=find(tosplit); 
tosplitnuc =  nuclbl>0 & tosplitlbl; 
tosplitnuclbl = bwlabel(tosplitnuc); 
cntr = regionprops(tosplitnuc,'Centroid'); 
nucxy = cat(1,cntr.Centroid); 
nnidx = annquery(nucxy',[x y]', size(nucxy,1));

ixnuc = grp2cell(tosplitnuclbl(:),tosplitlbl(:));
ixnuc = cellfun(@(x) setdiff(x,0),ixnuc,'uniformoutput',0);

sep=zeros(nnz(tosplit),1); 
% fprintf('need to split %g cells\n',n);
for i=1:n
    ix = find(tosplitlbl(tosplit)==i);
    r=zeros(numel(ixnuc{i}),numel(ix)); 
    for j=1:numel(ixnuc{i})
        [r(j,:),~]=find(nnidx(:,ix)==ixnuc{i}(j)); 
    end
    [~,mi]=min(r);
    sep(ix)=ixnuc{i}(mi);
end
lbl=zeros(size(bw));
lbl(tosplit) = sep;
lblnosplit = bwlabel(nottosplit)+max(lbl(:)); 
lbl(nottosplit) = lblnosplit(nottosplit);
lbl = seperateLbl(lbl); 

%% clean up any forground pixels that doesn't have a nuc in it
nuccell=grp2cell(lbl(:),nuclbl(:));
nuccell=setdiff(cat(1,nuccell{:}),0);
bw=ismember(lbl,nuccell);
lbl=bwlabel(bw);

%% relabel nuc
nucbw=nuclbl>0;
nuclbl = lbl;
nuclbl(~nucbw)=0;


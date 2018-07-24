function lbl=labelcellswithnucUsingImgAsWell(bw,nuclbl,I,Reg)
% this function labels a mask based on a combination of "traditional"
% bwlabel and splitting large multinuclei cells into parts. 


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
    
%% split cells using watershed
[tosplitlbl,n]=bwlabel(tosplit);
if max(tosplit(:))==0
    lbl=bwlabel(bw);
    return
end

sep=false(size(bw));

Iopn=imopen(I,strel('disk',15));
Icmp = mat2gray(imcomplement(Iopn));
for i=1:n
    tosplitnuc = nuclbl>0 & tosplitlbl==i;
    D = mat2gray(bwdist(tosplitnuc)) + Reg * Icmp;
    DL = watershed(D);
    sep(DL==0 & tosplitlbl==i)=true; 
end

bw2 = bw; 
bw2(sep)=0; 
lbl=bwlabel(bw2); 

%% seperate the labels & relabel
lbl=seperateLbl(lbl);
lbl=bwlabel(lbl>0);

%% clean up any forground pixels that doesn't have a nuc in it
nuccell=grp2cell(lbl(:),nuclbl(:));
nuccell=setdiff(cat(1,nuccell{:}),0);
bw=ismember(lbl,nuccell);
lbl=bwlabel(bw);


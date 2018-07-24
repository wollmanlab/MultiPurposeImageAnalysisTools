function [lbl,seeds] = segmentUsingSeeds(bw,seeds,varargin)


arg.method = 'watershed'; % tri
arg.mincellarea=0; 
arg.maxcellarea=Inf; 
arg.peaksupress=[]; 
arg.keeponlyseedwithcell = true; % will remove labeld area without a seed in it. 
                                 %  & will remove seeds that don't have a cell on them. 
arg.relabelbasedonseeds = true; 
arg = parseVarargin(varargin,arg); 


switch arg.method
    case 'tri'
        %% use delunay triangulation to assign pixels to cells
        pk = bwmorph(seeds,'shrink',Inf); 
        [y,x]=find(pk); 
        [r,c]=find(bw);
        tri=DelaunayTri(x,y);
        id = nearestNeighbor(tri,c,r);
        lbl=zeros(size(bw));
        lbl(sub2ind(size(bw),r,c))=id;
    case 'watershed'
        %%
        dst = bwdistgeodesic(bw,seeds>0,'quasi-euclidean');
        dst(isnan(dst))=-Inf;
        dst(isinf(dst))=Inf; 
        lbl = watershed(dst,8);
        lbl(~bw | isinf(dst))=0; 
end

%% find labels to get rid of
PxlIds = regionprops(lbl,'PixelIdxList'); 
PxlIds = {PxlIds.PixelIdxList};
Size = cellfun(@numel,PxlIds)'; 
CellsToRemove_indx = find(Size<arg.mincellarea | Size >arg.maxcellarea);

% 
% if arg.removewithoutseed
%     lbl = bwlabel(bw); 
%     nuccell=grp2cell(lbl(:),seeds(:));
%     nuccell=setdiff(cat(1,nuccell{:}),0);
%     bw=ismember(lbl,nuccell);
% end
    
if arg.keeponlyseedwithcell
    ls_pairs = unique([lbl(:) seeds(:)],'rows');
    ix = ls_pairs(:,1) ==0 | ls_pairs(:,2)==0;
    ls_pairs = ls_pairs(~ix,:);
    CellsToRemove_indx = [CellsToRemove_indx; setdiff(unique(lbl(:)),ls_pairs(:,1))];
    CellsToRemove_indx = setdiff(CellsToRemove_indx,0); 
end

PxlIds(CellsToRemove_indx)=[]; 

%% remove seeds without a forground
if arg.keeponlyseedwithcell
    bw = false(size(lbl));
    for i=1:numel(PxlIds)
        bw(PxlIds{i})=true;
    end
    seeds(~bw)=0;
end

%% relabel - at this point each label should have only a single seed
lbl = zeros(size(lbl)); 
for i=1:numel(PxlIds)
    indx = unique(seeds(PxlIds{i})); 
    indx(indx==0)=[];  
    if numel(indx)~=1, warning('unexpected dual cell within a seed - skipping'), continue, end 
                       % this should never be the case, but it is
                       % for now I'm skipping these cases....
    lbl(PxlIds{i})=indx; 
end


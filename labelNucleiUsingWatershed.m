function nuclbl = labelNucleiUsingWatershed(nucbw,hWtrshd,maxNucArea,minNucArea)

% segment nuclei
 dst=bwdist(~nucbw);
 dst(~nucbw)=-Inf;
 dst=imhmax(dst,hWtrshd);
 nuclbl=watershed(-dst);
 nuclbl(~nucbw)=0;
 
%% find labels to get rid of
PxlIds = regionprops(nuclbl,'PixelIdxList'); 
PxlIds = {PxlIds.PixelIdxList}; 
Size = cellfun(@numel,PxlIds); 
PxlIds(Size<minNucArea | Size >maxNucArea)=[]; 

%% relabel
nuclbl = zeros(size(nuclbl)); 
for i=1:numel(PxlIds)
    nuclbl(PxlIds{i})=i; 
end
 
%  nuclbl=seperateLbl(nuclbl);
%  tbl=tabulate(nuclbl(:));
%  nuclbl(ismember(nuclbl(:),tbl(tbl(:,2)>maxNucArea | tbl(:,2)<minNucArea,1)))=0;
%  nuclbl=bwlabel(nuclbl>0);
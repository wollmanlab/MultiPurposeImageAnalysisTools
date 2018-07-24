function [bw,lbl,n,xy]=segmentUsingVoroniAndMaxAsSeed(img,h,minCellArea,varargin)
% segments an image by simple threshold and voronoi using the regional
% maximal as seeds

%% parse varargin & set defaults
arg.msk=true(size(img));
arg.threshold_transform='none';
arg.threshold_method='otsu';
arg.threshold_minnumofobjects=0;
arg.filter='none';
arg.nndist=0; % allows seperating touching object but might lose sone objects...
arg.maxcellsize=numel(img);
arg.filter_nncutoff=sqrt(minCellArea);
arg.seedsxy=[]; % can give seeds xy directly and supress the max based calculation
for i=1:2:length(varargin)
    arg.(varargin{i})=varargin{i+1};
end

%% if image is not double transform it into one
switch class(img)
    case {'double','single'}
    case 'uint16'
        img=mat2gray(img,[0 2^16]);
    case 'uint8' 
        img=mat2gray(img,[0 2^8]);
end


%% segment using simple threshold & clean too small objects
% bw=im2bw(img,graythresh(img));
% persistent thrsh;

bw=optThreshold(img,'msk',arg.msk,...
                    'transform',arg.threshold_transform,...
                    'method',arg.threshold_method,...
                    'minnumofobjects',arg.threshold_minnumofobjects);
%[bw,t,ok]=optThreshold(img,'msk',arg.msk);
bw=bwareaopen(bw,minCellArea);
bw=bw & ~bwareaopen(bw,arg.maxcellsize);

%% create the seeds using the regional maxima after suppresion of too small peaks
if isempty(arg.seedsxy)
    sprs=imhmax(img,h);
    seeds=imregionalmax(sprs);
    seeds=seeds & bw;
    
    %% do the voronoi thing using the centroids of the peaks
    [X,Y]=meshgrid(1:size(seeds,2),1:size(seeds,1));
    lbl=bwlabel(seeds);
    [~,~,x]=grp2cell(X(:),lbl(:));
    [~,~,y]=grp2cell(Y(:),lbl(:));
    xy=[x y];
else
    xy=arg.seedsxy;
end

%% if requested filter (removes artifact cells based on some criteria)
switch arg.filter
    case 'none'
    case 'clusters'
        [NN,d]=annquery(xy',xy',2);
        xy=xy(d(2,:)>arg.filter_nncutoff,:);
    otherwise
        error('unsupported filtering of poitns');
end
n=size(xy,1);
if n==1 % no need to seperate objects and such
    lbl=bwlabel(bw);
    return
end

%% adding to each point in BW an index based on the knearest neighbour
% of the maxima
[r,c]=find(bw);

%% use ann to assign pixels to cells
tri=DelaunayTri(xy(:,1),xy(:,2));

% [id,dist]=annquery(xy',[c(:) r(:)]',2);
% ix=find(dist(2,:)-dist(1,:)>arg.nndist);
% r=r(ix);
% c=c(ix);
% id=id(1,ix);


id = nearestNeighbor(tri,c,r); 
lbl=zeros(size(bw));
lbl(sub2ind(size(bw),r,c))=id;
lbl((lbl>0) & ~bwareaopen(lbl>0,minCellArea))=0;

% renumber lbl such that it is continous from 1 to max(lbl(:))
emptyids=setdiff(1:size(unique(lbl(:)))-1,lbl(:));
tobigids=setdiff(lbl(:),0:size(unique(lbl(:)))-1);
for i=1:length(tobigids)
    lbl(lbl==tobigids(i))=emptyids(i);
end
bw=lbl>0;






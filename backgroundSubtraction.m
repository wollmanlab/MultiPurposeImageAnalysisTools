function [I,bck,bcksml] = backgroundSubtraction(I,varargin)
% background substruction of a segmented image. 
% 

sz = size(I);

if ~isa(I,'double') && ~isa(I,'single')
    warning('Data was not in double - tansforming it to be double using mat2gray!!!');
    I=mat2gray(I);
end

% default arguments
arg.smoothmethod='spline'; % 'none' (note that smoothing also take cares of NaN if exist)  - used to be tpaps
arg.msk=true(sz); % other can be any logical mask of what could be background
arg.samplingmethod='block'; % 'grid' 
arg.percentile=0; % only relevant if the samplngfcn uses percentile and than it define what percentile it is.  
arg.samplingfcn=@(x) prctile(x,arg.percentile);   
orgsamplingfcn=arg.samplingfcn; 
arg.samplingdensity=15;
arg.fgauss=fspecial('gauss',11,5);
arg.interpmethod='bilinear';
arg.smoothstk = false; 

arg.timefilter = sum(fspecial('gauss',15,10)); 
arg.timeskip = 1; 

arg = parseVarargin(varargin,arg); 

% deal with the case of a 0% sampling function
if arg.percentile==0 && isequal(orgsamplingfcn,arg.samplingfcn)
    arg.samplingfcn = @(x) min(x);
end

if arg.percentile~=0 && isequal(orgsamplingfcn,arg.samplingfcn)
    arg.samplingfcn=@(x) prctile(x,arg.percentile);
end


if ndims(I)==3
    %% subtrack background one slice at a time
    bck = zeros(size(I),'single');
    if arg.timeskip==1
        for i=1:size(I,3)
             [~,b]=backgroundSubtraction(I(:,:,i),arg);
            bck(:,:,i)=b; 
        end
    else
        for i=1:arg.timeskip:size(I,3)
            [~,bck(:,:,i)]=backgroundSubtraction(I(:,:,i),arg);
            for j=1:arg.timeskip
                if i+j<size(I,3)
                    bck(:,:,i+j)=bck(:,:,i);
                end
            end
        end
    end
    
    if arg.smoothstk 
        sz = size(bck);
        try
            bckrow = gpuArray(reshape(bck,sz(1)*sz(2),sz(3))');
        catch
            warning('Problem with GPU!')
            bckrow = reshape(bck,sz(1)*sz(2),sz(3))';
        end
        bckrow = imfilter(bckrow,arg.timefilter(:),'symmetric');
        bck = gather(reshape(bckrow',sz));
        
        %     bck = imfilter(bck,permute(arg.timefilter(:),[3 2 1]),'symmetric');
    end

    I = I - bck; 
    I(I<0)=0; 
    bcksml=[]; % just in case user asked for it... 
    return
end
       

Imsk=I; 
Imsk(~arg.msk)=NaN;




%% sample bckgroud pixels using either grid or blocks (~mask = NaN)
switch arg.samplingmethod
    case 'grid'
        % set up sampling grid. 
        c = floor(linspace(1,sz(2),arg.samplingdensity));
        r = floor(linspace(1,sz(1),arg.samplingdensity));
        [c,r]=meshgrid(c,r);

        % sample from block within the image
        bcksml=zeros(size(r));
        bcksml(:)=Imsk(sub2ind(sz,r(:),c(:)));
        
        
    case 'block'
        blksz=bestblk(sz,max(sz)/arg.samplingdensity);
        if sum(sz./blksz)-floor(sum(sz./blksz))==0
            % if the blocks are perfect fit, use im2col instead
            Icol = im2col(Imsk,blksz,'distinct');
            bcksml = arg.samplingfcn(Icol);
            bcksml = reshape(bcksml,sz./blksz); 
        else % use blocproc 
            f = @(x) arg.samplingfcn(x.data(:));
            bcksml=blockproc(Imsk,blksz,f);
        end
        r=(blksz(1)/2):blksz(1):sz(1);
        c=(blksz(2)/2):blksz(2):sz(2);
        [c,r]=meshgrid(c,r);
    otherwise
        error('unsupported samplind method')
end

%% replace NaNs with nearest not nan neighbour (could do better....)
[yi,xi]=find(isnan(bcksml));
[y,x]=find(~isnan(bcksml));
d=distance([x y]',[xi yi]');
[~,mi]=min(d);
x=x(mi);
y=y(mi);
ix = sub2ind(size(bcksml),y,x);
bcksml(isnan(bcksml))=bcksml(ix);

%% Smooth 
ix=find(~isnan(bcksml));
switch arg.smoothmethod
    case 'none'
        msksml=imresize(arg.msk,size(bcksml));
        bcksml(~msksml)=mean(I(arg.msk>0));
    case 'griddata'
        % fit a
        [x,y]=meshgrid(1:sz(2),1:sz(1));
        bcksml=griddata(c(ix),r(ix),double(bcksml(ix)),x,y);
        % get rid of the NaNs at the edge of the griddata interpolation
        [rstart,cstart]=find(~isnan(bcksml),1);
        [rend,cend]=find(~isnan(bcksml),1,'last');
        bcksml=bcksml(rstart:rend,cstart:cend);
        bcksml=imresize(bcksml,sz);
    case 'triscatter'
        F = TriScatteredInterp(c(ix),r(ix),bcksml(ix));
        [x,y]=meshgrid(1:sz(2),1:sz(1));
        bcksml = F(x,y);
    case 'spline'
        % thin plate spline fitting to points
        st = tpaps([c(ix) r(ix)]',bcksml(ix)');
        avals = fnval(st,[c(:) r(:)]'); % evaluate tps function
        % transform tps values from vector to matrix form
        bcksml = reshape(avals,size(r));
    case 'gauss'
        bcksml = imfilter(bcksml,arg.fgauss,'symmetric');
    otherwise
        error('unsupported smoothing method')
end

%% Interpolate back to big size
bck=imresize(bcksml,sz,arg.interpmethod);
if isa(I,'single')
    bck = single(bck);
end

I=imsubtract(I,bck);
I(I<0)=0;



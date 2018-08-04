function [stk,tformsall] = registerStack(stk,varargin)

arg.reference=ceil(size(stk,3)/2); 
% which slice to use as reference, use middle as default
% alternatice, to use more than one reference image, registerStack could be 
% callled with the reference argument as a struct with two fields: onlyspecificframes and
% reference. When called as a struct please provide the onlyspecificframes
% for each of the reference points
arg.crop = [ceil(size(stk,1)/3) ceil(size(stk,2)/3) ceil(size(stk,1)/3) ceil(size(stk,2)/3)]; 
arg.method='xcorr';
arg.filter=[]; 
arg.maxdisp=Inf; 
arg.onlyspecificframes=[]; % default (when empty) is to do use all frames
arg = parseVarargin(varargin,arg); 

%% if using more than one ref frame, create multiple calls for registerStack and return
if isstruct(arg.reference)
    
    stkcell = cell(numel(arg.reference),1);    
    tformcell = cell(size(stkcell)); 
    for i=1:numel(arg.reference)
        ix = arg.reference(i).onlyspecificframes; 
        argcall=arg;
        argcall.reference = arg.reference(i).reference;
        argcall.onlyspecificframe = ix;
        [stkcell{i},tformcell{i}] = registerStack(stk(:,:,ix),arg);
    end
    stk = cat(3,stkcell{:}); 
    tformsall = cat(2,tformcell{:}); 
    return
end

% assuming it is sorted, let's force it for good measure. 
arg.onlyspecificframes=sort(arg.onlyspecificframes); 

if isempty(arg.onlyspecificframes)
    ix=setdiff(1:size(stk,3),arg.reference);
else
    ix=arg.onlyspecificframes; 
end

if isempty(ix)
    tformsall=affine2d(); 
    return
end


%% Init a bunch of stacks, images etc. 
[optimizer,metric] = imregconfig('monomodal'); 
refimg = imcrop(stk(:,:,arg.reference),arg.crop); 
if ~isempty(arg.filter)
    refimg=imfilter(refimg,arg.filter); 
end
ref2d = imref2d([size(stk,1) size(stk,2)]);
smlstk=stk(:,:,ix);
tforms(size(smlstk,3))=affine2d(); 
crp=arg.crop; 
mtd=arg.method; 
flt=arg.filter;

if strcmp(mtd,'xcorr')
    try
        refimg=gpuArray(refimg);
        gputest = true;
    catch
        gputest = false;
end

if strcmp(mtd,'rascal')
    error('not implemented yet'); 
    [RefFeatures,RefPnt] = getFeaturesUsingPeaks(refimg);  %#ok<UNRCH>
end
    

%% identify transformation for each image (could be a subset) 
for i=1:numel(ix)
    img = imcrop(smlstk(:,:,i),crp); 
    if ~isempty(flt)
        img=imfilter(img,flt);
    end
    switch mtd
        case 'rascal'
            error('not implemented yet!')
            [Features,Pnt] = getFeaturesUsingPeaks(img); %#ok<UNRCH>
            indexPairs = matchFeatures(Features,RefFeatures); 
        case 'phasecorr'
            tforms(i) = imregcorr(img,refimg,'translation')';
        case 'intensity'
            tforms(i) = imregtform(img,refimg,'translation',optimizer, metric);
        case 'xcorr'
            if gputest
                img = gpuArray(img); 
            end
            cc=normxcorr2(img,refimg);
            [~, imax] = max(abs(cc(:)));
            imax=gather(imax);
            [ypeak, xpeak] = ind2sub(size(cc),imax(1));
            ypeak=ypeak-crp(3); 
            xpeak=xpeak-crp(4);
            tforms(i) = affine2d([eye(2) zeros(2,1); xpeak ypeak 1]);
        case 'intensity_with_xcorr'
            cc=normxcorr2(img,refimg);
            [~, imax] = max(abs(cc(:)));
            [ypeak, xpeak] = ind2sub(size(cc),imax(1));
            ypeak=ypeak-crp(3); 
            xpeak=xpeak-crp(4);
            xcorrtform = affine2d([eye(2) zeros(2,1); xpeak ypeak 1]); 
            % use the xcorr as intial guess for intensity based search. 
            tforms(i) = imregtform(img,refimg,'translation',optimizer, metric,'InitialTransformation',xcorrtform);
    end
    if sqrt(sum(tforms(i).T(3,1:2).^2))>arg.maxdisp
        tforms(i)=affine2d(); 
    end
    
end

%% fill up potentially missing transofrmations
tformsall(size(stk,3))=affine2d(); 
if isempty(arg.onlyspecificframes)
    tformsall(ix)=tforms;
    stk(:,:,ix)=gather(smlstk);
else
    ix=[ix(:); size(stk,3)+1]; 
    for i=1:numel(ix)-1
        tformsall(ix(i):ix(i+1)-1)=tforms(i); 
    end
end

% transform output stack
for i=1:size(stk,3)
    stk(:,:,i) = imwarp(stk(:,:,i),tformsall(i),'OutputView',ref2d);
end

end


% private function. 
    function [Features,Pnt] = getFeaturesUsingPeaks(img)
        bwpeaks = imregionalmax(imhmax(imadjust(img),0.1));
        bwpeaks = bwmorph(bwpeaks,'shrink',Inf);
        bwpeaks = bwpeaks & ~bwareaopen(bwpeaks,2);
        [pntY,pntX]=find(bwpeaks);
        [Features,Pnt] = extractFeatures(img,[pntX(:) pntY(:)]);
    end

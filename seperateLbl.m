function lbl = seperateLbl(lbl,varargin)

arg.method='8hood';
arg=parseVarargin(varargin,arg);

switch arg.method
    case '8hood'
        % returns a matrix label where objects are seperated such that
        % lbl = bwlabel(lbl>0) applies
        
        lblshiftr=zeros(size(lbl));
        lblshiftr(2:end,:)=lbl(1:end-1,:);
        
        lblshiftrd=zeros(size(lbl));
        lblshiftrd(2:end,2:end)=lbl(1:end-1,1:end-1);
        
        lblshiftru=zeros(size(lbl));
        lblshiftru(2:end,1:end-1)=lbl(1:end-1,2:end);
        
        lblshiftl=zeros(size(lbl));
        lblshiftl(1:end-1,:)=lbl(2:end,:);
        
        lblshiftlu=zeros(size(lbl));
        lblshiftlu(1:end-1,1:end-1)=lbl(2:end,2:end);
        
        lblshiftld=zeros(size(lbl));
        lblshiftld(1:end-1,2:end)=lbl(2:end,1:end-1);
        
        lblshiftu=zeros(size(lbl));
        lblshiftu(1:end-1,:)=lbl(2:end,:);
        
        lblshiftd=zeros(size(lbl));
        lblshiftd(2:end,:)=lbl(1:end-1,:);
        
        brdr= (lblshiftru~=lbl | lblshiftld~=lbl | lblshiftlu ~= lbl | lblshiftrd~=lbl | lblshiftr~=lbl | lblshiftl~=lbl | lblshiftu~=lbl | lblshiftd~=lbl) & (lbl ~=0);
        lbl(brdr)=0;
    case 'thin'
        %%
        bw=lbl>0;
        brdr= ~rangefilt(mat2gray(bw))>0 & rangefilt(mat2gray(lbl))>0;
        brdr=imdilate(brdr,strel('disk',3));
        brdr=bwmorph(bwmorph(brdr,'thin',Inf),'clean');
        lbl(brdr)=0;
end
        
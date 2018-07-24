function prj=stackProject(files,varargin)
% perform a maximal projection givena list of file names, less memory
% intensive than loading them all as a big 3D matrix. 
% supports max / mean / user-defined projection functions
% includes options for background subtraction and level adjustments


%% deal with options
arg.lvl=[];
arg.background=0;
arg.verbose=0;
arg.func='max';
arg=parseVarargin(varargin,arg);

%% decide on projection function 
if ~ischar(arg.func) && ~isa(arg.func,'function_handle')
    error('Projection function must be a legit string code or a funcion handle of the form: @(img,prj,n)');
end
    
if ischar(arg.func)
    switch arg.func
        case 'max'
            arg.func=@(img,prj,n) max(img,prj);
        case 'mean'
            arg.func=@(img,prj,n) prj+img/n;
        otherwise
            error('unsupported projection function');
    end
end
            

%% get image size
info=imfinfo(files{1});
sz=[info.Height info.Width];
prj=zeros(sz);

arg.verbose && fprintf('started calculating projection at %s\n',datestr(now));
t0=now;
%% main loop
for t=1:length(files)
    img=imread(files{t});
    if ~isempty(arg.lvl)
        img=mat2gray(img,arg.lvl);
    end
    if arg.background
        img=backgroundSubtraction(img);
    end
    prj=arg.func(double(img),prj,length(files));
end

arg.verbose && fprintf('finish calculating projection at %s total of %s\n',datestr(now),datestr(now-t0,13));
function B=imrotate3_fast(varargin)
%IMROTATE3_FAST - fast rotation of 3-D grayscale image
% 
%     B = IMROTATE3_FAST(V,ANGLES) rotates the 3-D grayscale image V (in order)
%     by ANGLES(1) around the x axis, ANGLES(2) around the y axis, and ANGLES(3) 
%     around the Z axis. 
%
%     B = IMROTATE3_FAST(V,{ANGLES AXES}) rotates V by ANGLES around the 
%     corresponding AXES (in order) 
% 
%     B = IMROTATE3_FAST(...,METHOD) uses the interpolation method specified by 
%     METHOD. METHOD is a string that can have one of the follwing values:
%           'linear' or 'bilinear' - bilinear interpolation (default).
%           'cubic' or 'bicubic' - bicubic interpolation.
%           'nearest' - nearest neighbor interpolation. 
% 
%     This function is designed to leverage the very fast imrotatemex called by 
%     IMROTATE to perform 3-D rotations. R2017A's IMROTATE3 uses IMWARP, which 
%     is often considerably slower than performing rotations separately. Moreover, 
%     testing reveals that IMWARP/IMROTATE3 show comparable performance when 
%     applied to large matrices of doubles/16bit integers, and are considerably 
%     slower when applied to 8-bit integers. Conversely, IMROTATE is considerably 
%     faster with 16 and 8-bit integers.
% 
%     IMROTATE3_FAST takes Euler-type angles (user provides rotations around 
%     specified axes and their order). Performing 3D rotations using axis-angle 
%     (as in matlab's IMROTATE3) can be accomplished by converting from Euler to
%     axis-angle. The functions eul2aa and aa2eul have been included to demonstrate 
%     this (only XYZ rotations have been included for this demo).
%
%     The features incorporated by BBOX and FILLVAL parameters in imrotate3 are not 
%     included here...but they are trivially easy to add. IMROTATE3_FAST sets these
%     to their defaults, FILLVAL=0, BBOX='loose'.
%
%     Note that the results are not identical to imrotate3...that's because while 
%     imrotate3 works in true 3-D, imrotate3_fast treats interpolation problems in
%     2-D. For the large datasets on which this was tested the differences seem 
%     trivial, although there is a translation that results from the iterative 
%     permutation method that must come from the repeated definition of centers, 
%     but I haven't been able to reason. The function IMROTATE3_FAST_TESTER shows 
%     a comparison between the two methods. 
% 
%%
[V,ANGLES,AXLIST,METHOD]=parseinputs(varargin{:});
ord=[1 2 3]; %To avoid unnecessarily calling permute, I'll keep track of the current order of dimensions, wrt the original.
B=V;
for i = 1:numel(ANGLES)
    if ANGLES(i)~=0
        [B,ord]=dopermrotate(B,ANGLES(i),AXLIST(i),METHOD,ord);
    end
end
%finally, put it back in order:
[~,sortind]=sort(ord);
B=permute(B,sortind);
%suppose first is x, so i permute it to [1 3 2] 
%then next is y, so i want it to be [2 3 1] it was 1,3,2
%then next is z, so i want it to be [1 2 3]...
function [V,ANGLES,AXLIST,METHOD]=parseinputs(varargin)
%check inputs:
narginchk(2,4);
V = varargin{1};
validateattributes(V,{'numeric','logical'},{'ndims',3},mfilename,'V',1);
A = varargin{2};
validateattributes(A,{'numeric','cell'},{},mfilename,'ANGLES',2);
if iscell(A)
    ANGLES=A{1};
    AXLIST=A{2};
    if ~ischar(AXLIST) || numel(ANGLES)~=numel(AXLIST) || any(~ismember(upper(AXLIST),'XYZ'))
        error('AXES should be a character vector composed of ''X'' ''Y'' or ''Z'' with the same number of elements as ANGLES');
    else
        AXLIST=upper(AXLIST);
    end
else
    ANGLES=A;
    xyz='XYZ';
    AXLIST=xyz(1:numel(ANGLES));
end
if nargin>2
    METHOD=varargin{3};
    validateattributes(METHOD,{'char'},{},mfilename,'METHOD',3);
    if any(strcmpi(METHOD,{'linear' 'bilinear'}))
        METHOD='bilinear';
    elseif any(strcmpi(METHOD,{'cubic' 'bicubic'}))
        METHOD='bicubic';
    elseif strcmpi(METHOD,'nearest')
        METHOD='nearest';
    else
        error('METHOD should be: linear, bilinear, cubic, bicubic, or nearest')
    end
else
    METHOD='bilinear';
end
function [rotvol,newdim]=dopermrotate(vol,ang,ax,method,olddim)
if ax=='X'
    ang=ang*-1;
end
newdim=[find(~ismember('YXZ',ax)) find(ismember('YXZ',ax))]; %this is the permutation wrt original
usedim=[find(olddim==newdim(1)) find(olddim==newdim(2)) find(olddim==newdim(3))];  %this is permutation wrt current
rotvol=imrotate(permute(vol,usedim),ang,method);
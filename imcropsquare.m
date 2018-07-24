function [sml,rect,xynewcord]=imcropsquare(img,xycntr,sz,varargin)
% crops an square subimage based on center location and small image size
% shift center if necessary 

arg.bnd=[0 0 size(img,1) size(img,2)];
arg=parseVarargin(varargin,arg);

imgsz=size(img);
% if min(imgsz)<sz, 
%     error('cannot crop size bigger that image!');
% end

% imgsz=imgsz-arg.bnd;

xycntr_org=xycntr; 

% shift the center if necessary
xycntr(1)=max(xycntr(1),arg.bnd(1)+ceil(sz/2)+1);
xycntr(1)=min(ceil(xycntr(1)),imgsz(2)-ceil(sz/2));
xycntr(2)=max(xycntr(2),arg.bnd(2)+ceil(sz/2)+1);
xycntr(2)=min(ceil(xycntr(2)),imgsz(1)-ceil(sz/2));

dxdy=xycntr-xycntr_org; 
xynewcord = [sz/2 sz/2]-dxdy; 

% crop
rect=[xycntr(1)-floor(sz/2) xycntr(2)-floor(sz/2) sz sz];
sml=imcrop(img,rect);


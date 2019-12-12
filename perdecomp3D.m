function [p,s]=perdecomp3D(u,varargin)
% %   u : "input graylevel image",
% %   p : "periodic component",
% %   s : "smooth component"

[nx,ny,nz] = size(u);
  s = zeros(nx,ny,nz);

% %    fill "boundary image" 
  b1 = double(u(nx,:,:) - u(1,:,:));
  b2 = double(u(:,ny,:) - u(:,1,:));
  b3 = double(u(:,:,nz) - u(:,:,1));
  
  s(1,:,:)  = - b1;
  s(nx,:,:) =  b1; 
  
  s(:,1,:)  = s(:,1,:) - b2;
  s(:,ny,:) = s(:,ny,:) + b2;
  
  s(:,:,1)  = s(:,:,1) - b3;
  s(:,:,nz) = s(:,:,nz) + b3;

% %   Fourier transform 
  fft3_s=fftn(s);
 
  cx = 2.0*pi/double(nx);
  cy = 2.0*pi/double(ny);
  cz = 2.0*pi/double(nz);

% %  frequencies computation
  mat_x=double(repmat([0:(round(nx/2)-1) (floor(nx/2)):-1:1]',[1,ny,nz]));
  mat_y=double(repmat([0:(round(ny/2)-1) (floor(ny/2)):-1:1],[nx,1,nz]));
  mat_z=permute(double(repmat([0:(round(nz/2)-1) (floor(nz/2)):-1:1],[nx,1,ny])),[1 3 2]);

  b=0.5./double(3.0-cos(cx*mat_x)-cos(cy*mat_y)-cos(cz*mat_z));
  fft3_s = fft3_s .* b;
  
% %  (0,0) frequency
  fft3_s(1,1,1) = 0.0;
  
% %  inverse Fourier transform 
  s=real(ifftn(fft3_s));
  
% %   get p=u-s 
  p = double(u)-s;
function r=aa2eul(ax,ang)
%where r specifies rotation around the x,y,z axes, 
%ax,ang specify the same rotation as a single angle ang around an axis ax
%I'll intermediate my way through quaternions, using angle2quat:
q(1)=cosd(ang/2);
%sum(ax^2) must be normalized to equal 1:
ax=ax./sqrt(sum(ax.^2));
q(2)=ax(1)*sind(ang/2);
q(3)=ax(2)*sind(ang/2);
q(4)=ax(3)*sind(ang/2);
[r(1),r(2),r(3)]=quat2angle(q,'XYZ');
r=rad2deg(r);
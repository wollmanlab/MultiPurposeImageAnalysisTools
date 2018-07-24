function imshowlinked(varargin)

clf

if numel(varargin)==2
    pos = [0 0 0.5 1; 0.5 0 0.5 1];
elseif numel(varargin)==3
    pos = [0 0 0.5 0.5; 0.5 0 0.5 0.5; 0.5 0.5 0.5 0.5];
elseif numel(varargin)==4
    pos = [  0   0 0.5 0.5;
           0.5   0 0.5 0.5; 
           0.5 0.5 0.5 0.5; 
             0 0.5 0.5 0.5];
else
    error('unsiupported number of inputs');
end

for i=1:numel(varargin)
    h(i) = axes('position',pos(i,:),'units','normalized');
    imagesc(varargin{i},[0 1])
    axis equal
    set(gca,'xtick',[],'ytick',[])
end
colormap gray
linkaxes(h)
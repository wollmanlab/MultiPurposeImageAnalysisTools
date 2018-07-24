function interactiveIJROImeasrements(stk,varargin)

arg.axis = []; 
arg.fig = []; 
arg.resize=1; 
arg.fcn = @(m,r) mean(m(r)); 
arg.pause = 0.1; 
arg = parseVarargin(varargin,arg); 

if isempty(arg.fig)
    fig = figure; 
else
    fig = arg.fig; 
    figure(fig); 
end

clf
set(fig,'ToolBar','none');
ht = uitoolbar(fig);
htt1 = uitoggletool(ht,'state','on','Cdata',rand(16,16,3));

title('ready')

xyold= [];
I=[]; 

while strcmp(get(htt1,'state'),'on')

    xy = MIJ.getRoi(0);
    
    
   
    plot(I)
    if isequal(xy,xyold)
        title('ready')
    else
        title('processing...')
    end
    pause(arg.pause);
    
    c = xy(2,:)/arg.resize;
    r = xy(1,:)/arg.resize;
    r = roipoly(stk(:,:,1),c,r);
    I = stkfun(arg.fcn,stk,r);
    
    xyold=xy; 
end




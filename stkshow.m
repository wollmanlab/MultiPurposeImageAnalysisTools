function ip = stkshow(stk,varargin)

% stkshow 

% arguments

% title - either a single string or a cell array of strings



warning('off','MATLAB:Java:ConvertFromOpaque')

if ~exist('MIJ','class')

    try 

        ImageJ; 

    catch

        Miji;

    end;

end



if ischar(stk) && strcmp(stk,'close')

    MIJ.closeAllWindows;

    return

end

   

if ~isempty(inputname(1))

    arg.title = inputname(1);

else

    arg.title = 'Stack';

end

arg.level = [0 2^16]; 

arg.resize = 1; 

arg = parseVarargin(varargin,arg);

 





%% "recursive" run if asked to show multiple stacks

if iscell(stk)

    ip = cell(size(stk)); 

    for i=1:numel(stk)

        if iscell(arg.title)

            ip{i} = stkshow(stk{i},'title',arg.title{i},'level',arg.level,'resize',arg.resize); 

        else

            ip{i} = stkshow(stk{i},'title',arg.title,'level',arg.level,'resize',arg.resize); 

        end

    end

    return

end



%% convert stack into uin16

if arg.resize ~=1 

    if ndims(stk)>3

        error('cann''t resize an rgb image')

    end

    f = @(m) imresize(m,arg.resize,'nearest'); 

    stk = stkfun(f,stk);

end



if ~isequal(arg.level,[0 2^16])

    stk = mat2gray(stk,arg.level/2^16);

end

stk = uint16(stk*2^16);



%% show image as ImageJ window

if ndims(stk)>3

    ip = MIJ.createColor(arg.title,uint8(stk/256),true); 

else

    ip = MIJ.createImage(arg.title,stk,true);

end





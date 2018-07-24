function O = stkfun(f,M,varargin)
% the stack aquivalent of cellfun or arrayfun but smarter
% cur now varargin is an additional matrix of either size of M or another
% arbitrary size. If its has the same number of slices as M that only a
% slice is passed everytime (not matter what's its size, that f's problem)
% if size(M,3) ~= size(A,3) than its passed as is to f(m,a) again f's
% should know how to deal with it. 

% is the size of
    
if ~isempty(varargin)
    A=varargin{1};
    if size(M,3)==size(A,3)
        %% test the first one for size
        m=M(:,:,1);
        a=A(:,:,1);
        Ofirst=f(m,a);
        O=repmat(Ofirst,[1 1 size(M,3)]);
        parfor i=2:size(M,3)
            m=M(:,:,i);
            a=A(:,:,i);
            O(:,:,i)=f(m,a); %#ok<PFBNS>
        end
    else
        %% test the first one for size
        m=M(:,:,1);
        a=A;
        Ofirst=f(m,a);
        O=repmat(Ofirst,[1 1 size(M,3)]);
        parfor i=2:size(M,3)
            m=M(:,:,i);
            O(:,:,i)=f(m,a); %#ok<PFBNS>
        end
    end
else
    %% no additional arguments
    %% test the first one for size
    m=M(:,:,1);
    Ofirst=f(m);
    O=repmat(Ofirst,[1 1 size(M,3)]);
    parfor i=2:size(M,3)
        m=M(:,:,i);
        O(:,:,i)=f(m); %#ok<PFBNS>
    end
end

O=squeeze(O);




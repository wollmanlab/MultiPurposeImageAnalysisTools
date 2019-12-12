function C = convnfft(A, B, varargin)
% CONVNFFT  FFT-BASED N-dimensional convolution.
%   C = CONVNFFT(A, B) performs the N-dimensional convolution of
%   matrices A and B. If nak = size(A,k) and nbk = size(B,k), then
%   size(C,k) = max([nak+nbk-1,nak,nbk]);
% 
%   C = CONVNFFT(A, B, SHAPE) controls the size of the answer C:
%       'full'   - (default) returns the full N-D convolution
%       'same'   - returns the central part of the convolution that
%                  is the same size as A.
%       'valid'  - returns only the part of the result that can be
%                  computed without assuming zero-padded arrays.
%                  size(C,k) = max([nak-max(0,nbk-1)],0).
%
%   C = CONVNFFT(..., SHAPE, DIMS) with DIMS is vector of dimensions where
%       the convolution will be carried out. By default DIMS is
%       [1:max(ndims(A),ndims(B))] (all dimensions). A and B must have the
%       same lengths on other dimensions.
%   C = CONVNFFT(..., SHAPE, DIMS, GPU)
%       GPU is boolean flag, see next
%
%   C = CONVNFFT(..., SHAPE, DIMS, ...)
%
%   Optional Arguments:
%     
%         UsePowerOfTwo: true/false
%         
%             rounds the dimension to the nearest power of 2 by zero-padding 
%             while doing the FFT. It is faster but requires more memory.
%             Default-value: true
%
% Class support for inputs A,B:
% float: double, single
%
% METHOD: CONVNFFT uses Fourier transform (FT) convolution theorem, i.e.
%         FT of the convolution is equal to the product of the FTs of the
%         input functions.
%         In 1-D, the complexity is O((na+nb)*log(na+nb)), where na/nb are
%         respectively the lengths of A and B.
%
% Usage recommendation:
%         In 1D, this function is faster than CONV for nA, nB > 1000.
%         In 2D, this function is faster than CONV2 for nA, nB > 20.
%         In 3D, this function is faster than CONVN for nA, nB > 5.
% 
% See also conv, conv2, convn.
% 
%   Author: Deepak Roy Chittajallu
%  
%   Fix input parsing. Alon Oyler-Yaniv 


    nd = max(ndims(A),ndims(B));


    
    shape = ParseInputs('shape','full',varargin);
    dims = ParseInputs('dims',1:nd,varargin);
    flagUseGPU = ParseInputs('UseGPU',false,varargin);
    flagPower2 = ParseInputs('UsePowerOfTwo',false,varargin);


    if flagUseGPU
        flagUseGPU = true; % for not this not supported
    end
        
    dims = reshape(unique(dims), 1, []); % row (needed for for-loop index)

    % IFUN function will be used later to truncate the result
    % M and N are respectively the length of A and B in some dimension
    switch lower(shape)
        case 'full',
            ifun = @(m,n) 1:m+n-1;
        case 'same',
            ifun = @(m,n) ceil((n-1)/2)+(1:m);
        case 'valid',
            ifun = @(m,n) n:m;
        otherwise
            error('convnfft: unknown shape %s', shape);
    end

    ABreal = isreal(A) && isreal(B);

    % make dimension a power of 2 if needed
    if flagPower2
        % faster FFT if the dimension is power of 2
        lfftfun = @(l) 2^nextpow2(l);
    else
        % slower, but smaller temporary arrays
        lfftfun = @(l) l;
    end

    % Compute the FFTs
    if flagUseGPU

        % pad arrays with zeros
        subsA(1:ndims(A)) = {':'};
        subsB(1:ndims(B)) = {':'};
        
        
        m = size(A);
        n = size(B);
        
        for dim=dims
            
            l = lfftfun(m(dim)+n(dim)-1);               
            
            if l < m(dim)
                subsA(1:ndims(A)) = {':'};
                subsA{dim} = 1:l;
                A = A(subsA{:});
            elseif l > m(dim)
                subsA(1:ndims(A)) = {':'};
                subsA{dim} = m(dim)+1:l;
                A(subsA{:}) = 0;
            end
            
            if l < n(dim)
                subsB(1:ndims(B)) = {':'};
                subsB{dim} = 1:l;
                B = B(subsB{:});
            elseif l > n(dim)
                subsB(1:ndims(B)) = {':'};
                subsB{dim} = m(dim)+1:l;
                B(subsB{:}) = 0;
            end
        end
        
        % make gpy arrays
        A = gpuArray(A);
        B = gpuArray(B);
        
        % do the fft
        subs(1:ndims(A)) = {':'};

        for dim=dims
            % We need to swap dimensions because GPU FFT works along the first dimension
            if dim~=1 % do the work when only required
                %swap = 1:nd;
                %swap([1 dim]) = swap([dim 1]);
                A = permute(A, [2:nd 1]);
                B = permute(B, [2:nd 1]);
            end
            
            l = lfftfun(m(dim)+n(dim)-1); 
            
            A = fft(A,l);
            B = fft(B,l);
            
            subs{dim} = ifun(m(dim),n(dim));
        end
        A = permute(A, [2:nd 1]);
        B = permute(B, [2:nd 1]);
        
    else
        
        subs(1:ndims(A)) = {':'};
        for dim=dims

            m = size(A,dim);
            n = size(B,dim);
            
            l = lfftfun(m+n-1);
            
            A = fft(A,l,dim);
            B = fft(B,l,dim);
            subs{dim} = ifun(m,n);

        end            
        
    end    

    % multiply the ffts of A and B element-wise 
    C = A .* B;


    
    % translate C back from frequency domain
    for dim=dims
        C = ifft(C,[],dim);
    end
    
    if flagUseGPU
        C = gather(C);
    end
    
    % Truncate the results
    if ABreal
        % Make sure the result is real
        C = real(C(subs{:}));
    else
        C = C(subs{:});
    end
            

    
end


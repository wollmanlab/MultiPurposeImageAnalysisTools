function W = awt3DRemBG(I, varargin)
    % W = AWT(I) computes the A Trou Wavelet Transform of image I.
    % A description of the algorithm can be found in:
    % J.-L. Starck, F. Murtagh, A. Bijaoui, "Image Processing and Data
    % Analysis: The Multiscale Approach", Cambridge Press, Cambridge, 2000.
    %
    % W = AWT(I, nBands) computes the A Trou Wavelet decomposition of the
    % image I up to nBands scale (inclusive). The default value is nBands =
    % ceil(max(log2(N), log2(M))), where [N M] = size(I).
    %
    % Output:
    % W contains the wavelet coefficients, an array of size N x M x nBands+1.
    % The coefficients are organized as follows:
    % W(:, :, 1:nBands) corresponds to the wavelet coefficients (also called
    % detail images) at scale k = 1...nBands
    % W(:, :, nBands+1) corresponds to the last approximation image A_K.
    %
    % You can use awtDisplay(W) to display the wavelet coefficients.
    %
    % Sylvain Berlemont, 2009
    
    [N, M, L] = size(I);
    
    K = ceil(max([log2(N), log2(M), log2(L)]));
    
    nBands = K;
    
    if nargin > 1 && ~isempty(varargin{1})
        nBands = varargin{1};
        
        if nBands < 1 || nBands > K
            error('invalid range for nBands parameter.');
        end
    end
    
    W = zeros(N, M, L);
    
    I = double(I);
    lastA = I;
    
    for k = 1:nBands
        newA = convolve(lastA, k);
        W = W + (lastA - newA).*single(k>1);
        lastA = newA;
    end
    
    W = W + min(lastA(:));
    
    
function F = convolve(I, k)
    [N, M, L] = size(I);
    k1 = 2^(k - 1);
    k2 = 2^k;
    
    tmp = padarray(I, [k2 0 0], 'replicate');
    
    % Convolve the columns
    I = 6*tmp(k2+1:end-k2, : , :) + 4*(tmp(k2+k1+1:end-k2+k1, :, :) + tmp(k2-k1+1:end-k2-k1, :, :))...
        + tmp(2*k2+1:end, :, :) + tmp(1:end-2*k2, :, :);
    
    tmp = padarray(I * .0625, [0 k2 0], 'replicate');
    
    % Convolve the rows
    I = 6*tmp(:,k2+1:end-k2, :) + 4*(tmp(:,k2+k1+1:end-k2+k1, :) + tmp(:,k2-k1+1:end-k2-k1, :))...
        + tmp(:,2*k2+1:end, :) + tmp(:,1:end-2*k2, :);
    
    
        tmp = padarray(I * .0625, [0  0 k2], 'replicate');
    
    % Convolve the stack
    I = 6*tmp(:, :,k2+1:end-k2) + 4*(tmp(:, :,k2+k1+1:end-k2+k1) + tmp(:, :,k2-k1+1:end-k2-k1))...
        + tmp(:, :,2*k2+1:end) + tmp(:, :,1:end-2*k2);
    
    
    F = I * .0625;
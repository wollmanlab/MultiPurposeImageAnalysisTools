function Data = removeHotPixels(Data)
nFrames = size(Data,3);
for i=1:nFrames
    fmap1 = Data(:,:,i);
    
    flt = [1 1 1; 1 0 1; 1 1 1]./8;
    U = imfilter(fmap1,flt,'replicate');
    [h,x] = histcounts(reshape((fmap1-U),[],1),1000);
    J = cumsum(h)/sum(h)>.999;
    ind2switch = find((fmap1-U) >= min(x(J)));
    
    
    for repInd = 1:size(ind2switch)
        [I,J] = ind2sub([size(fmap1,1) size(fmap1,2)], ind2switch(repInd));
        if I>1 && I<size(fmap1,1) && J>1 && J<size(fmap1,2)
            fmap1(I,J) = (fmap1(I+1,J)+fmap1(I-1,J)+fmap1(I,J+1)+fmap1(I,J-1)+...
                fmap1(I+1,J+1)+fmap1(I-1,J+1)+fmap1(I+1,J-1)+fmap1(I-1,J-1))/8;
            %sides
        elseif I==1 && J>1 && J<size(fmap1,1)
            fmap1(I,J) = (fmap1(I+1,J)+fmap1(I,J+1)+fmap1(I,J-1)+...
                fmap1(I+1,J+1)+fmap1(I+1,J-1))/5;
            
        elseif I==size(fmap1,1) && J>1 && J<size(fmap1,2)
            fmap1(I,J) = (fmap1(I-1,J)+fmap1(I,J+1)+fmap1(I,J-1)+...
                fmap1(I-1,J+1)+fmap1(I-1,J-1))/5;
            
        elseif I>1 && I<size(fmap1,1) && J==1
            fmap1(I,J) = (fmap1(I+1,J)+fmap1(I-1,J)+fmap1(I,J+1)+...
                fmap1(I+1,J+1)+fmap1(I-1,J+1))/5;
            
        elseif I>1 && I<size(fmap1,1) &&  J==size(fmap1,2)
            fmap1(I,J) = (fmap1(I+1,J)+fmap1(I-1,J)+fmap1(I,J-1)+...
                fmap1(I+1,J-1)+fmap1(I-1,J-1))/5;
            %corners
        elseif I==1 && J==1
            fmap1(I,J) = (fmap1(I+1,J)+fmap1(I,J+1)+...
                fmap1(I+1,J+1))/3;
            
        elseif I==size(fmap1,1) && J==1
            fmap1(I,J) = (fmap1(I-1,J)+fmap1(I,J+1)+...
                fmap1(I-1,J+1))/3;
            
        elseif I==1 &&  J==size(fmap1,2)
            fmap1(I,J) = (fmap1(I+1,J)+fmap1(I,J-1)+...
                fmap1(I+1,J-1))/3;
            
        elseif I==size(fmap1,1) &&  J==size(fmap1,2)
            fmap1(I,J) = (fmap1(I-1,J)+fmap1(I,J-1)+...
                +fmap1(I-1,J-1))/3;
        end;
    end
    Data(:,:,i) = fmap1;
end
end
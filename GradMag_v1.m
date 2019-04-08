function Im = GradMag_v1(A) 
    f = fspecial('sobel');
    Im = sqrt(imfilter(A, f, 'replicate').^2+ imfilter(A, f', 'replicate').^2);
end
function Im = GradMag_v2(A) 
    f = fspecial('sobel');
    Im = sqrt(imfilter(A, f, 0).^2+ imfilter(A, f', 0).^2);
end
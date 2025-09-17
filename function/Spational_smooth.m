function out = Spational_smooth(src,idx)
%  Function:    Select different smoothing coefficients according to the gear level for spatial smoothing processing
%  Parameters:  src            -   input data                          
%               idx            -   the level
%           
%  Return:      out            -   Spatially smoothed data
if(idx==0)
    out = src;
elseif(idx==1)
    h = fspecial('gaussian', [3,3], 0.75);
    out = imfilter(src,h,'replicate','same');
elseif(idx==2)
    h = fspecial('gaussian', [3,3], 1);
    out = imfilter(src,h,'replicate','same');
elseif(idx==3)
    h = fspecial('gaussian', [5,5], 1.2);
    out = imfilter(src,h,'replicate','same');
elseif(idx==4)
    h = fspecial('gaussian', [5,5], 2);
    out = imfilter(src,h,'replicate','same');

else
    out = src;


end
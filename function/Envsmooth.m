function out = Envsmooth(src)
%  Function: Smoothing the envelope data
%  Parameters:  src       -   input data                    
%
%  Return:      out       -   Smoothed data

coef = gausswin(3,1.2);
out = conv2(src,coef,'same');

end
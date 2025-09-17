function out = Filter(src,type,order,wn)
%  Function:    performs FIR low-pass filtering on the data, with the filter 
%               designed using a window function.
%  Parameters:  src       -   input data  
%               type      -   window function
%               wn        -   The cut-off frequency,wn must be between 0 < Wn < 1.0
%               order     -   filter order
% 
%  Return:      out       -   filtered data


if(strcmp(type,'hamming'))
    coef = fir1(order-1,wn,"low",hamming(order));
elseif(strcmp(type,'hanning'))
    coef = fir1(order-1,wn,"low",hamming(order));
elseif(strcmp(type,'gaussian'))
    coef = fir1(order-1,wn,"low",gausswin(order,1.2));
end
out = conv2(src,coef','same');


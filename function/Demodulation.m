function out = Demodulation(src,demo_depth,demo_fre,fs,c)
%  Function: IQ Demodulation
%  Parameters:  src            -   Input data                          
%               demo_depth     -   Demodulation depth
%               demo_fre       -   The corresponding demodulation frequency at different depths
%               fs             -   Sampling frequency
%               c              -   Velocity of sound
%
%  Return:      out            -   IQ data
           
[sample_num ,line_num]= size(src);
interval = c/fs/2;
depth = interval*(sample_num-1);
target_fre = Interp(demo_depth,demo_fre,depth,sample_num);
target_fre = repmat(target_fre',1,line_num);
out = sqrt(2)*src.*exp(-1i*2*pi*target_fre/fs.*(0:sample_num-1)');


end
function out = Interp(a,b,c,d)
% Function: Linear interpolation
if(a(end)<c)
    a = [a,c];
    b = [b,b(end)];
end
if(a(1)>0)
    a = [0,a];
    b = [b(1),b];
end
target_a = linspace(0,c,d); 

out = interp1(a,b,target_a);
end

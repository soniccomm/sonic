function [frespec,line_fre] = fpectral_analyse(data,fs)
%  Function:    Spectrum Analysis
%  Parameters:  data        -   Input data  
%               fs          -   Sampling frequency
% 
%  Return:      line_fre    -   frequency spectrum analysis horizontal coordinate
 %              frespec     -   frequency spectrum analysis vertical coordinate 
[m,n] = size(data);
fftlen = 2^nextpow2(m);
if(fftlen<1024)
    fftlen = 1024;
end

line_fre = fs*linspace(-0.5,0.5,fftlen);

Y =  abs(fft(data,fftlen))/fftlen;
frespec =  abs(fftshift(fft(data,fftlen)))/fftlen;

end


% data = IQ;
% M = 15
% c = 1540;
% f0 = 5e6;
function [arfidata] = ARFI_displacement(data,M,c,f0)
[col,~,Frames] = size(data);
data(:,1,1) = zeros(col,1,1);
data_temp = movsum(data,M);
refdata = data_temp(:,:,1:Frames-1);
comdata = data_temp(:,:,2:Frames);
nu = real(comdata).*imag(refdata)-imag(comdata).*real(refdata);
de = real(comdata).*real(refdata)+imag(comdata).*imag(refdata);
displace_est = atan2(nu,de);
arfidata = displace_est * (c/(f0*4*pi));
end
function [out]= DAS_PlaneWave(src,x_axis,z_axis,rx_apod,fs,sos,probe,steer)
% Function: Beamforming : DAS
%  ========================================================================
%                                das iq
%  ========================================================================
[x_grid, z_grid] = meshgrid(x_axis,z_axis);
[Nz,Nx] = size(x_grid);

steering = deg2rad(steer);
x_grid = reshape(x_grid,[Nz*Nx,1]);
z_grid = reshape(z_grid,[Nz*Nx,1]);
% 计算发射和接收延时
xm = bsxfun(@minus,probe.element_pos.x,x_grid);
zm = bsxfun(@minus,probe.element_pos.z,z_grid);
rx_delay = sqrt(xm.^2+zm.^2)/sos ;         
if steering >= 0
    tx_delay = ((x_grid - min(probe.element_pos.x))*sin(steering) + z_grid*cos(steering))/sos;
else
    tx_delay = ((max(probe.element_pos.x) - x_grid)*sin(-steering) + z_grid*cos(steering))/sos;
end


t = (0:size(src,1)-1)/fs;

rf_data = src;
% beamforming and compounding
for k = 1:size(rx_delay,2)
    temp_delay = (tx_delay + rx_delay(:,k));
    if k == 1
       bfrf = rx_apod(:,k).*interp1(t,rf_data(:,k),temp_delay,"linear",0);

    else
        bfrf = bfrf + rx_apod(:,k).*interp1(t,rf_data(:,k),temp_delay,"linear",0);

    end



end
out = reshape(bfrf,Nz,Nx);

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





































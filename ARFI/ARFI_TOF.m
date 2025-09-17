% arfidata = dirdata;
% ROI_Axial = 401:1000;
% ROI_Lateral = 80:120;
% PRT = 1/2000;
% N_pixel = 5;
% pixel_pitch = 3e-4;
% Time_Interp_Factor = 5;
function [vel_map] = ARFI_TOF(arfidata,ROI_Axial,ROI_Lateral,PRT,N_pixel,pixel_pitch,Time_Interp_Factor)
    [~,lateral,time] = size(arfidata);
    max_lat = min(lateral-N_pixel,max(ROI_Lateral));
    min_lat = max(1+N_pixel,min(ROI_Lateral));
    ROI_Lateral = min_lat:max_lat;
    dt = 1/Time_Interp_Factor;
    for i = ROI_Axial
        for j = ROI_Lateral
            x1 = reshape(arfidata(i,j-N_pixel,:),1,[]);
            x2 = reshape(arfidata(i,j+N_pixel,:),1,[]);
            x1_interp = interp1(1:time,x1,1:dt:time,'spline');
            x2_interp = interp1(1:time,x2,1:dt:time,'spline');
            xcorr_data = xcorr(x2_interp,x1_interp,'biased');
            t1 = find(xcorr_data == max(xcorr_data));
            td(i-min(ROI_Axial)+1,j-min(ROI_Lateral)+1) = (t1(1)-length(x1_interp))/Time_Interp_Factor;
        end
    end
    vel_map = ((2*N_pixel)*pixel_pitch)./(td*PRT);
end
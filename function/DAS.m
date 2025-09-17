function out = DAS(src,js_line,aper,sample_num,fs,sos,channel,probe)
% Function: Beamforming : DAS
startx = js_line.start_x;
startz = js_line.start_z;
setpx = js_line.step_x;
setpz = js_line.step_z;
cstartoffset = js_line.cstartoffset;
x = zeros(sample_num,1);
if(setpx)

   x = (0:setpx:(sample_num-1) * setpx)+ startx;
else
   x(:) =  startx;
end
z = (0:setpz:(sample_num-1) * setpz)+ startz;
z= z';

jswin  = aper.js_win;
fn_depth = aper.fn_depth;
fn_value = aper.fn_value;
min_aper = aper.min_Aper;
max_aper = aper.max_Aper;
apod = zeros(sample_num,channel);


interval = sos/fs/2;
depth = interval*(sample_num-1);
f_n = Interp(fn_depth,fn_value,depth,sample_num);

tx_dis = sqrt((x-x(1)).^2+(z-z(1)).^2);
rx_dis = sqrt((x-probe.element_pos.x).^2+(z-probe.element_pos.z).^2);
js_arrays = round(tx_dis ./ f_n'./probe.element_pitch);
js_arrays = min(max(js_arrays , min_aper) , max_aper);
[~ , index] = min(abs(probe.element_pos.x - x(1)));
left_index = round(max(index - js_arrays / 2 , 1));
right_index = round(min(index + js_arrays / 2 , channel));
apodL = right_index-left_index+1;
for k = 1:sample_num
    apod(k,left_index(k):right_index(k)) = jswin(floor(linspace(1,256,apodL(k))));
end

dis = rx_dis + repmat(tx_dis,1,channel);
delay = dis   /sos  * fs ;
delaypt = delay+   cstartoffset;
% [X,Y] = meshgrid(1:channel, 1:size(src,1));

[X,Y] = meshgrid(1:channel, 1:size(src,1));
[X1,Y1] = meshgrid(1:channel, 1:sample_num);

temp =  interp2(X, Y, src, X1, delaypt, 'linear', 0);

out = sum(temp.*apod,2);


end













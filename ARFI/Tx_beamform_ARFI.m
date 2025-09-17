% steers = pw_tx_angle;para = AcqConfig;txwave = txwave;
function [out,ScanList,rx ]= Tx_beamform_ARFI(steers,para,txwave,revloc,ARFI_tx_focus_depth,Ref_Frame_Nums,Track_Frame_Nums,Ex_Aperture,ARFI_Pulse_Num,ARFI_Pulse_Frequency)

if(nargin==2)
    txwave.voltage = 50;
    txwave.pulse_num = 1 ;
    txwave.pulse_duration = 1;
    txwave.pulse_frequency = 5e6;
    txwave.pulse_Polarity = 1 ;

end
probe = para.Probe;                        %探头参数
channel= para.Tx.channel;                  %发射通道
sos = para.Tx.sos;                         %声速
fs = para.Rx.fs;                           %采样率
sample_num = para.Rx.Revpt;                %采样点数
voltage = txwave.voltage;                  %发射电压
pulse_num = txwave.pulse_num ;             %发射周期数
pulse_duration =  txwave.pulse_duration;   %脉冲占空比
pulse_frequency = txwave.pulse_frequency ; %脉冲频率
pulse_Polarity = txwave.pulse_Polarity ;   %脉冲极性
Ex_Frame_num = length(ARFI_tx_focus_depth);%ARFI激励帧数
tx_num = length(steers)*Ref_Frame_Nums+Ex_Frame_num+length(steers)*Track_Frame_Nums;   %总帧数  
ARFI_pulse_duration = 0.9;
angles = deg2rad(steers);                  %平面波角度

%%
for i = 1:length(steers)*Ref_Frame_Nums
    idx =  i;
    if(idx==1)
        ScanList(idx).Framestart = 1;
        ScanList(idx).Frameend = 0;

    else
        ScanList(idx).Framestart = 0;
        ScanList(idx).Frameend = 0;
    end
    out.sequence{idx}.active = ones(1,channel);  % 阵元是否激励
    active_temp =  ones(channel,1);
    out.sequence{idx}.delay = zeros(1,channel);   % 阵元激励延时
    out.sequence{idx}.delay = (probe.element_pos.x  - min(probe.element_pos.x )) * tan(angles(mod((i)-1,length(steers))+1))/sos;
    out.sequence{idx}.delay= out.sequence{idx}.delay - min( out.sequence{idx}.delay(active_temp== 1),[],'all');
    cstartoffset = 0;
    rx.sequence{idx}.start_x = revloc.start_x;
    rx.sequence{idx}.start_y = 0;
    rx.sequence{idx}.start_z = revloc.start_z;
    rx.sequence{idx}.x_num = revloc.x_num;

    rx.sequence{idx}.step_x = revloc.step_x;

    rx.sequence{idx}.steer = steers(mod((i)-1,length(steers))+1);
    rx.sequence{idx}.step_y = 0;
    rx.sequence{idx}.step_z = revloc.step_z;
    rx.sequence{idx}.z_num = revloc.z_num;
    rx.sequence{idx}.cstartoffset = cstartoffset;
    % out.sequence{idx}.delay = max(out.sequence{idx}.delay(active_temp),[],'all') - out.sequence{idx}.delay;
    % cstartoffset(idx) =  max(out.sequence{idx}.delay(active_temp),[],'all')*fs;

    %计算发射波形
    out.sequence{idx}.pulse_num = pulse_num;
    out.sequence{idx}.pulse_duration = pulse_duration;
    out.sequence{idx}.pulse_frequency = pulse_frequency;
    out.sequence{idx}.pulse_polarity = pulse_Polarity;
    out.sequence{idx}.pulse_voltage = voltage;

    ScanList(idx).PluseType = out.sequence{idx}.pulse_polarity;
    ScanList(idx).Sln = idx-1;
    ScanList(idx).SampleN = sample_num;


end
%%
ARFI_Aperature = size(Ex_Aperture,2);
active_temp = 65-ARFI_Aperature/2:64+ARFI_Aperature/2;
for i = length(steers)*Ref_Frame_Nums+1:length(steers)*Ref_Frame_Nums+Ex_Frame_num
    idx =  i;
    if(idx==1)
        ScanList(idx).Framestart = 1;
        ScanList(idx).Frameend = 0;

    else
        ScanList(idx).Framestart = 0;
        ScanList(idx).Frameend = 0;
    end
    %计算发射孔径位置
    out.sequence{idx}.active = zeros(1,channel);  % 阵元是否激励
    out.sequence{idx}.active(1,Ex_Aperture) = 1;
    %计算发射延时
    out.sequence{idx}.delay = zeros(1,channel);   % 阵元激励延时
    delay_temp = sqrt( (probe.element_pos.x).^2 + (probe.element_pos.z - ARFI_tx_focus_depth(idx-length(steers)*Ref_Frame_Nums)).^2 )/sos;
    delay_temp = max(delay_temp(active_temp),[],'all') - delay_temp;
    out.sequence{idx}.delay(1,Ex_Aperture) = [delay_temp(active_temp)];
    
    cstartoffset =  0;

    %计算发射波形
    out.sequence{idx}.pulse_num = ARFI_Pulse_Num;
    out.sequence{idx}.pulse_duration = ARFI_pulse_duration;
    out.sequence{idx}.pulse_frequency = ARFI_Pulse_Frequency;
    out.sequence{idx}.pulse_polarity = pulse_Polarity;
    out.sequence{idx}.pulse_voltage = voltage;

    ScanList(idx).PluseType = out.sequence{idx}.pulse_polarity;
    ScanList(idx).Sln = idx-1;
    ScanList(idx).SampleN = sample_num;

    rx.sequence{idx}.start_x = revloc.start_x;
    rx.sequence{idx}.start_y = 0;
    rx.sequence{idx}.start_z = revloc.start_z;
    rx.sequence{idx}.x_num = revloc.x_num;

    rx.sequence{idx}.step_x = revloc.step_x;

    rx.sequence{idx}.steer = 0;
    rx.sequence{idx}.step_y = 0;
    rx.sequence{idx}.step_z = revloc.step_z;
    rx.sequence{idx}.z_num = revloc.z_num;
    rx.sequence{idx}.cstartoffset = cstartoffset;
end
%%
for i = length(steers)*Ref_Frame_Nums+Ex_Frame_num+1:tx_num
    idx =  i;
    if(idx==1)
        ScanList(idx).Framestart = 1;
        ScanList(idx).Frameend = 0;

    else
        ScanList(idx).Framestart = 0;
        ScanList(idx).Frameend = 0;
    end
    out.sequence{idx}.active = ones(1,channel);  % 阵元是否激励
    active_temp =  ones(channel,1);
    out.sequence{idx}.delay = zeros(1,channel);   % 阵元激励延时
    out.sequence{idx}.delay = (probe.element_pos.x  - min(probe.element_pos.x )) * tan(angles(mod((i-length(steers)*Ref_Frame_Nums-Ex_Frame_num)-1,length(steers))+1))/sos;
    out.sequence{idx}.delay= out.sequence{idx}.delay - min( out.sequence{idx}.delay(active_temp== 1),[],'all');
    cstartoffset = 0;
    rx.sequence{idx}.start_x = revloc.start_x;
    rx.sequence{idx}.start_y = 0;
    rx.sequence{idx}.start_z = revloc.start_z;
    rx.sequence{idx}.x_num = revloc.x_num;

    rx.sequence{idx}.step_x = revloc.step_x;

    rx.sequence{idx}.steer = steers(mod((i-length(steers)*Ref_Frame_Nums-Ex_Frame_num)-1,length(steers))+1);
    rx.sequence{idx}.step_y = 0;
    rx.sequence{idx}.step_z = revloc.step_z;
    rx.sequence{idx}.z_num = revloc.z_num;
    rx.sequence{idx}.cstartoffset = cstartoffset;

    %计算发射波形
    out.sequence{idx}.pulse_num = pulse_num;
    out.sequence{idx}.pulse_duration = pulse_duration;
    out.sequence{idx}.pulse_frequency = pulse_frequency;
    out.sequence{idx}.pulse_polarity = pulse_Polarity;
    out.sequence{idx}.pulse_voltage = voltage;

    ScanList(idx).PluseType = out.sequence{idx}.pulse_polarity;
    ScanList(idx).Sln = idx-1;
    ScanList(idx).SampleN = sample_num;


end

if(tx_num>1)
    ScanList(idx).Framestart = 0;
end
ScanList(idx).Frameend = 1;

end
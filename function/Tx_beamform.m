function [out,ScanList,cstartoffset ]= Tx_beamform(tx_line,para,txwave)
%  Function    :  Configure transmission waveform and transmission delay
%  Parameters  :  tx_line       -   The location of the transmission line
%                 para          -   includes probe parameters, channels, sampling rate, sound speed, and focus position
%                 txwave        -   includes transmission frequency, transmission voltage, period, and duty cycle
%  Return:        out           -   Transmission waveform and transmission delay parameters
%                 ScanList      -   Scan line header information
%                 cstartoffset  -   The time from the start of the transmission to the effective
if(nargin==2)
    txwave.voltage = 50;
    txwave.pulse_num = 1 ;
    txwave.pulse_duration = 1;
    txwave.pulse_frequency = 5e6;
    txwave.pulse_Polarity = 1 ;

end
probe = para.Probe;
focus_depth = para.Tx.focus_depth;
aperture= para.Tx.aperture;
channel= para.Tx.channel;
sos = para.Tx.sos;
fs = para.Rx.fs;
sample_num = para.Rx.Revpt;
voltage = txwave.voltage;
pulse_num = txwave.pulse_num ;
pulse_duration =  txwave.pulse_duration;
pulse_frequency = txwave.pulse_frequency ;
pulse_Polarity= txwave.pulse_Polarity ;
tx_num = length(tx_line.x);
minnum = min(probe.element_num,channel);
maxnum = max(probe.element_num,channel);
for i = 1:tx_num
    idx =  i;
    if(idx==1)
        ScanList(idx).Framestart = 1;
        ScanList(idx).Frameend = 0;

    else
        ScanList(idx).Framestart = 0;
        ScanList(idx).Frameend = 0;
    end
    tmp_dist = abs(probe.element_pos.x - tx_line.x(i));
    tx_center_idxs = find(tmp_dist == min(tmp_dist));
    tx_center_idx = tx_center_idxs(1);
    theta = probe.element_pos.theta(tx_center_idx);
    %发射起始点
    out.sequence{idx}.start_x = tx_line.x(i);
    out.sequence{idx}.start_y = tx_line.y(i);
    out.sequence{idx}.start_z = tx_line.z(i);
    %计算发射聚焦点位置
    out.sequence{idx}.focus_x =  tx_line.x(i)+focus_depth*sin(theta);
    out.sequence{idx}.focus_y =  tx_line.y(i) ;
    out.sequence{idx}.focus_z = focus_depth*cos(theta);
    %计算发射孔径位置
    out.sequence{idx}.active = zeros(1,maxnum);  % 阵元是否激励
    active_temp = (tx_center_idx - aperture/2):(tx_center_idx + aperture/2 -1);
    if(aperture==1)
        active_temp = tx_center_idx;
    end
    active_temp(active_temp <= 0) = [];
    active_temp(active_temp > minnum) = [];
    out.sequence{idx}.active(1,active_temp) = 1;
    %计算发射延时
    out.sequence{idx}.delay = -1*ones(1,maxnum);    % 阵元激励延时
    out.sequence{idx}.delay(1,1:minnum) = sqrt( (probe.element_pos.x - out.sequence{idx}.focus_x).^2 + (probe.element_pos.z - out.sequence{idx}.focus_z).^2 )/sos;
    out.sequence{idx}.delay(1,1:minnum) = max(out.sequence{idx}.delay(active_temp),[],'all') - out.sequence{idx}.delay(1,1:minnum);
    if(strcmp(probe.type,'phase')||strcmp(probe.type,'convex'))
         cstartoffset(idx) =  max(out.sequence{idx}.delay(tx_center_idx),[],'all')*fs;
    else
         cstartoffset(idx) =  max(out.sequence{idx}.delay(active_temp),[],'all')*fs;
    end

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

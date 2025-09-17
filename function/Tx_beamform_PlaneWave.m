function [out,ScanList,rx ]= Tx_beamform_PlaneWave(steers,para,txwave,revloc)

if(nargin==2)
    txwave.voltage = 50;
    txwave.pulse_num = 1 ;
    txwave.pulse_duration = 1;
    txwave.pulse_frequency = 5e6;
    txwave.pulse_Polarity = 1 ;

end
probe = para.Probe;
channel= para.Tx.channel;
sos = para.Tx.sos;
fs = para.Rx.fs;
sample_num = para.Rx.Revpt;
voltage = txwave.voltage;
pulse_num = txwave.pulse_num ;
pulse_duration =  txwave.pulse_duration;
pulse_frequency = txwave.pulse_frequency ;
pulse_Polarity = txwave.pulse_Polarity ;
tx_num = length(steers);
angles = deg2rad(steers);
for i = 1:tx_num
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
    out.sequence{idx}.delay = (probe.element_pos.x  - min(probe.element_pos.x )) * tan(angles(i))/sos;
    out.sequence{idx}.delay= out.sequence{idx}.delay - min( out.sequence{idx}.delay(active_temp== 1),[],'all');
    cstartoffset = 0;
    rx.sequence{idx}.start_x = revloc.start_x;
    rx.sequence{idx}.start_y = 0;
    rx.sequence{idx}.start_z = revloc.start_z;
    rx.sequence{idx}.x_num = revloc.x_num;

    rx.sequence{idx}.step_x = revloc.step_x;

    rx.sequence{idx}.steer = steers(idx);
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
if(tx_num>1)
    ScanList(idx).Framestart = 0;
end
ScanList(idx).Frameend = 1;

end

function dev_manager = DAQ(AcqConfig,ScanList,libpath,Revpt,CaptureSpeed)

tx_chan_ind = AcqConfig.Probe.tx_ele_map;
%%  库路径
NET.addAssembly(libpath); %确定.NET集的地址，加载环境

%% 创建设备管理器
dev_manager = DAQ_SDK_C.DeviceManager(1, ...
    AcqConfig.Probe.element_num*numel(AcqConfig.Tx.sequence)+2, ...
    numel(AcqConfig.Tx.sequence), ...
    1, ...
    1, ...
    2);
dev_manager.sensor_num = AcqConfig.Tx.channel;
%% 通道采样次数
dev_manager.DAQ_args.sample_num = Revpt;

%% 采样频率,单位MHz
dev_manager.DAQ_args.ADC_fs = AcqConfig.Tx.fs/1e6;
%% 采集速度
%设置DAQ为内触发还是外触发，true为内触发，false为外触发
dev_manager.DAQ_args.trigger_mode = 1;
%设置内部触发器的频率，单位Hz


if(CaptureSpeed>100)
    dev_manager.DAQ_args.trigger_fs = CaptureSpeed;
    dev_manager.frame_num_in_callback = round(CaptureSpeed/50);

elseif(CaptureSpeed<=12)
    dev_manager.DAQ_args.trigger_fs = CaptureSpeed;
    dev_manager.frame_num_in_callback = CaptureSpeed;
else
    dev_manager.DAQ_args.trigger_fs = CaptureSpeed;
    dev_manager.frame_num_in_callback = round(CaptureSpeed/2);
end
dev_manager.DAQ_args.trigger_delay1 = 76;
dev_manager.DAQ_args.trigger_delay2 = 76;
dev_manager.DAQ_args.trigger_delay3 = 76;

dev_manager.DAQ_args.enable_upload = 6;
dev_manager.DAQ_args.TGC_gain1 = 0;
dev_manager.DAQ_args.TGC_gain2 = 0;
dev_manager.DAQ_args.TGC_gain3 = 0;
dev_manager.DAQ_args.VCA_gain1 = 0;
dev_manager.DAQ_args.VCA_gain2 = 0;
dev_manager.DAQ_args.VCA_gain3 = 0;
dev_manager.DAQ_args.trigger_shield = 0;
dev_manager.DAQ_args.merge_channel_num = 0;
dev_manager.DAQ_args.enable_2_network = 0;
dev_manager.DAQ_args.extra_port_num = 0;

%% AFE寄存器配置

if(dev_manager.DAQ_args.ADC_fs==80 )
    AFE_Registers =  [2 3 4 5 21 33 45 57 67 154 155 156 195 196 197 203];
    AFE_Register_values = [0 0 0 13652 5 5 5 5 0 1024 10098 0 5 8448 0 200];    
else
    AFE_Registers =  [2 3 4 5 21 33 45 57 67 154 155 156 195 196 197 203];
    AFE_Register_values = [0 32792 1 13652 5 5 5 5 0 1024 10098 0 5 8448 0 200];    

end



for i = 1:length(AFE_Registers)
    AFE_Register  = AFE_Registers(i);
    AFE_Register_value =  AFE_Register_values(i);
    dev_manager.AFE_regs.set_afe_reg(int32(AFE_Register), uint32(AFE_Register_value));
    pause(0.005);
end
%%  配置发射参数

% 0xBF:单脉冲发射 0xBE:极性相反 0x7F:连续脉冲发射 0x7E:极性相反 0x3F:不发射
% 电压配置
disp("configuring transmit voltage ...");
voltage_commmand_val =  AcqConfig.Tx.sequence{1}.pulse_voltage * 3153 * 16 / 100;
%配置发射电压

dev_manager.DAQ_args.set_tx_arg(0, 1,0,...
    AcqConfig.Tx.sequence{1}.pulse_duration,...
    AcqConfig.Tx.sequence{1}.pulse_num,...
    AcqConfig.Tx.sequence{1}.delay(1)*240e6,...
    AcqConfig.Tx.sequence{1}.pulse_frequency/1e6,...
    0x3F,....
    0x5AFF,...
    voltage_commmand_val);
dev_manager.DAQ_args.set_tx_arg(1, 1,0,...
    AcqConfig.Tx.sequence{1}.pulse_duration,...
    AcqConfig.Tx.sequence{1}.pulse_num,...
    AcqConfig.Tx.sequence{1}.delay(1)*240e6,...
    AcqConfig.Tx.sequence{1}.pulse_frequency/1e6,...
    0x3F,....
    0x5AFE,...
    voltage_commmand_val);

pause(0.001);

% 其他发射参数配置
disp("configuring transmit sequence ...");
command_code = 0x3aff;
for tx_idx = 0:numel(AcqConfig.Tx.sequence)-1
    disp("configuring transmit sequence ["+num2str(tx_idx)+"]");
    %为1时，极性相反
    if(AcqConfig.Tx.sequence{tx_idx+1}.pulse_polarity==1)
        for element_idx = 1:AcqConfig.Probe.element_num

            if (AcqConfig.Tx.sequence{tx_idx+1}.active(element_idx))
                    dev_manager.DAQ_args.set_tx_arg((tx_idx*AcqConfig.Probe.element_num)+element_idx-1+2, tx_chan_ind(element_idx),tx_idx,...
                        AcqConfig.Tx.sequence{tx_idx+1}.pulse_duration,...
                        AcqConfig.Tx.sequence{tx_idx+1}.pulse_num,...
                        round(AcqConfig.Tx.sequence{tx_idx+1}.delay(element_idx)*240e6),...
                        AcqConfig.Tx.sequence{tx_idx+1}.pulse_frequency/1e6,...
                        0x7E,....
                        command_code,...
                        numel(AcqConfig.Tx.sequence)-1);

            else
                dev_manager.DAQ_args.set_tx_arg((tx_idx*AcqConfig.Probe.element_num)+element_idx-1+2, tx_chan_ind(element_idx),tx_idx,...
                    AcqConfig.Tx.sequence{tx_idx+1}.pulse_duration,...
                    AcqConfig.Tx.sequence{tx_idx+1}.pulse_num,...
                    round(AcqConfig.Tx.sequence{tx_idx+1}.delay(element_idx)*240e6),...
                    AcqConfig.Tx.sequence{tx_idx+1}.pulse_frequency/1e6,...
                    0x3F,....
                    command_code,...
                    numel(AcqConfig.Tx.sequence)-1);
            end
        end



    else

        for element_idx = 1:AcqConfig.Probe.element_num

            if AcqConfig.Tx.sequence{tx_idx+1}.active(element_idx)

                    dev_manager.DAQ_args.set_tx_arg((tx_idx*AcqConfig.Probe.element_num)+element_idx-1+2,tx_chan_ind(element_idx),tx_idx,...
                        AcqConfig.Tx.sequence{tx_idx+1}.pulse_duration,...
                        AcqConfig.Tx.sequence{tx_idx+1}.pulse_num,...
                        round(AcqConfig.Tx.sequence{tx_idx+1}.delay(element_idx)*240e6),...
                        AcqConfig.Tx.sequence{tx_idx+1}.pulse_frequency/1e6,...
                        0x7F,....
                        command_code,...
                        numel(AcqConfig.Tx.sequence)-1);
            else
                dev_manager.DAQ_args.set_tx_arg((tx_idx*AcqConfig.Probe.element_num)+element_idx-1+2,tx_chan_ind(element_idx),tx_idx,...
                    AcqConfig.Tx.sequence{tx_idx+1}.pulse_duration,...
                    AcqConfig.Tx.sequence{tx_idx+1}.pulse_num,...
                    round(AcqConfig.Tx.sequence{tx_idx+1}.delay(element_idx)*240e6),...
                    AcqConfig.Tx.sequence{tx_idx+1}.pulse_frequency/1e6,...
                    0x3F,....
                    command_code,...
                    numel(AcqConfig.Tx.sequence)-1);
            end

        end
    end
end


%% 配置发射序列头部的所有数据
for i = 1:size(ScanList,2)
    dev_manager.scan_heads.set_head(i-1,uint16(0), uint16(ScanList(i).Sln), uint8(0),  uint8(0), ...
        uint8(0), uint8(ScanList(i).PluseType),uint8(ScanList(i).Frameend), uint8(ScanList(i).Framestart), uint16(ScanList(i).SampleN));
end
%%  AFE滤波参数配置，已弃用，勿删

for i = 0:1
    dev_manager.DAQ_args.set_afe_filter(i, uint8(1), uint8(i), uint16(1),uint16(1),uint16(1), ...
        uint16(1),uint16(1),uint16(1),uint16(1),uint16(1));
end
profile_value = '0000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000100111';
profile_v = zeros(1,14);
for i = 1:14
    profile_v(i) = bin2dec(profile_value(i*8-7:i*8));
end

dev_manager.DAQ_args.set_afe_profile(0, 0, 0, fliplr(profile_v));
dev_manager.DAQ_args.set_afe_mode(0, 0, 0, 0, size(ScanList,2)-1, size(ScanList,2)-1);

pause(2.5);
end
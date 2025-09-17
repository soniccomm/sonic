function  [NumsPerFile,File_nums,prf] = DAQ_Acquisition(AcqConfig,ScanList,prf,frame,filepath)


lasting_time = frame*size(ScanList,2)/prf;

tx_chan_ind = AcqConfig.Probe.tx_ele_map;
ch_map = AcqConfig.Probe.rx_ele_map;

Revpt = AcqConfig.Rx.Revpt;
RxChannel = AcqConfig.Tx.channel;
TxChannel = AcqConfig.Tx.channel;

trigger_delay = 76;

% 库路径
if ~libisloaded('DAQ_SDK')
    loadlibrary('DAQ_SDK.dll', 'DAQ_SDK.h');
end
calllib("DAQ_SDK",'RunRealTime',size(ScanList,2),(32+AcqConfig.Rx.Revpt*RxChannel*2));


ptr = libpointer('cstring', filepath);
calllib('DAQ_SDK', 'SetIsSave',1,ptr);

%寄存器配置

if(AcqConfig.Tx.fs/1e6==80 )
    AFE_Registers =  [2 3 4 5 21 33 45 57 67 154 155 156 195 196 197 203];
    AFE_Register_values = [0 0 0 13652 5 5 5 5 0 1024 10098 0 7 8448 0 8];
else
    AFE_Registers =  [2 3 4 5 21 33 45 57 67 154 155 156 195 196 197 203];
    AFE_Register_values = [0 32792 1 13652 5 5 5 5 0 1024 10098 0 5 8448 0 8];
end


for i = 1:length(AFE_Register_values)
    AFE_Register  = AFE_Registers(i);
    AFE_Register_value =  AFE_Register_values(i);
    calllib('DAQ_SDK', 'set_afe_reg',AFE_Register,AFE_Register_value);
end

tvg_time = [0,346,623,900,1177,1455,1732,2009,2286,2563,2840,3117,3394,3671,3948];

% TGC
for i = 1:length(tvg_time)
    calllib('DAQ_SDK', 'set_tvg_arg',length(tvg_time),i-1, 0, tvg_time(i));
end

%%  配置发射参数
% 0xBF:单脉冲发射 0xBE:极性相反 0x7F:连续脉冲发射 0x7E:极性相反 0x3F:不发射
% 电压配置
Txseq.FsFrequency = round(240/( AcqConfig.Tx.sequence{1}.pulse_frequency/1e6));
Txseq.Duration = round(((1 - AcqConfig.Tx.sequence{1}.pulse_duration) * Txseq.FsFrequency/4));
Txseq.Pulse_num = AcqConfig.Tx.sequence{1}.pulse_num*2;
disp("configuring transmit voltage ...");
voltage_commmand_val = AcqConfig.Tx.sequence{1}.pulse_voltage * 3153 * 16 / 100;
calllib('DAQ_SDK', 'set_tx_arg',1,0, ...
    Txseq.Duration, ...
    Txseq.Pulse_num, ...
    uint16(round(AcqConfig.Tx.sequence{1}.delay(1)*240e6)), ...
    Txseq.FsFrequency, ...
    hex2dec('0x3F'),hex2dec('0x5AFF'), ...
    voltage_commmand_val);
calllib('DAQ_SDK', 'set_tx_arg',1,0, ...
    Txseq.Duration, ...
    Txseq.Pulse_num, ...
    uint16(round(AcqConfig.Tx.sequence{1}.delay(1)*240e6)), ...
    Txseq.FsFrequency, ...
    hex2dec('0x3F'),hex2dec('0x5AFE'), ...
    voltage_commmand_val);

pause(0.001);





% 其他发射参数配置
disp("configuring transmit sequence ...");
command_code = '0x3aff';
for tx_idx = 0:numel(AcqConfig.Tx.sequence)-1
    disp("configuring transmit sequence ["+num2str(tx_idx)+"]");
    %为1时，极性相反

    Txseq.FsFrequency = round(240/( AcqConfig.Tx.sequence{tx_idx+1}.pulse_frequency/1e6));
    Txseq.Duration = round(((1 - AcqConfig.Tx.sequence{tx_idx+1}.pulse_duration) * Txseq.FsFrequency/4));
    Txseq.Pulse_num = AcqConfig.Tx.sequence{tx_idx+1}.pulse_num*2;


    if(AcqConfig.Tx.sequence{tx_idx+1}.pulse_polarity==0)
        for element_idx = 1:TxChannel

            if (AcqConfig.Tx.sequence{tx_idx+1}.active(element_idx))
                    calllib('DAQ_SDK', 'set_tx_arg',tx_chan_ind(element_idx),tx_idx, ...
                        Txseq.Duration,...
                        Txseq.Pulse_num,...
                        uint16(round(AcqConfig.Tx.sequence{tx_idx+1}.delay(element_idx)*240e6)),...
                        Txseq.FsFrequency ,...
                        hex2dec('0x7E'), ...
                        hex2dec(command_code), ...
                        numel(AcqConfig.Tx.sequence)-1);

            else
                calllib('DAQ_SDK', 'set_tx_arg', tx_chan_ind(element_idx),tx_idx,...
                    Txseq.Duration,...
                    Txseq.Pulse_num,...
                    uint16(round(AcqConfig.Tx.sequence{tx_idx+1}.delay(element_idx)*240e6)),...
                    Txseq.FsFrequency ,...
                    hex2dec('0x3F'),....
                    hex2dec(command_code), ...
                    numel(AcqConfig.Tx.sequence)-1);

            end

        end



    else

        for element_idx = 1:TxChannel

            if (AcqConfig.Tx.sequence{tx_idx+1}.active(element_idx))

      
                    calllib('DAQ_SDK', 'set_tx_arg', tx_chan_ind(element_idx),tx_idx,...
                        Txseq.Duration,...
                        Txseq.Pulse_num,...
                        uint16(round(AcqConfig.Tx.sequence{tx_idx+1}.delay(element_idx)*240e6)),...
                        Txseq.FsFrequency ,...
                        hex2dec('0x7F'),....
                        hex2dec(command_code),...
                        numel(AcqConfig.Tx.sequence)-1);

            else
                calllib('DAQ_SDK', 'set_tx_arg', tx_chan_ind(element_idx),tx_idx,...
                    Txseq.Duration,...
                    Txseq.Pulse_num,...
                    uint16(round(AcqConfig.Tx.sequence{tx_idx+1}.delay(element_idx)*240e6)),...
                    Txseq.FsFrequency ,...
                    hex2dec('0x3F'),....
                    hex2dec(command_code),...
                    numel(AcqConfig.Tx.sequence)-1);

            end



        end
    end

end


% 一帧超声图像对应总线数  当前模式结束线号
calllib('DAQ_SDK', 'set_afe_mode',0,0,0,size(ScanList,2), size(ScanList,2));

profile_v = int32([0,0,0,0,0,0,0,0,0,0,0,0,0,16]);
bytePtr = libpointer('int32Ptr', fliplr(profile_v));
calllib('DAQ_SDK', 'set_afe_profile',0,0,bytePtr,length(profile_v));

AFEFilter.Filtercoef=[20,136,92,65068,64688,588,3928,6424;65520,72,164,65408,64752,65100,2140,5500];
AFEFilter.Rows = 2;
for i = 0:AFEFilter.Rows-1
    calllib('DAQ_SDK', 'set_afe_filter',AFEFilter.Rows-1, i, AFEFilter.Filtercoef(i+1,1),AFEFilter.Filtercoef(i+1,2),AFEFilter.Filtercoef(i+1,3), ...
        uint16(AFEFilter.Filtercoef(i+1,4)),AFEFilter.Filtercoef(i+1,5),AFEFilter.Filtercoef(i+1,6),AFEFilter.Filtercoef(i+1,7),AFEFilter.Filtercoef(i+1,8));
end


%每通道采样次数
Rx_sample_num = Revpt;

% %配置发射序列头部的所有数据
for i = 1:size(ScanList,2)

    calllib('DAQ_SDK', 'set_scanHead',0, ScanList(i).Sln, 0,  0, ...
        1, ScanList(i).PluseType,ScanList(i).Frameend, ScanList(i).Framestart, ScanList(i).SampleN);
end

 % seqNums = frames*size(AcqConfig.Tx.sequence,2);
% [TotalLines,frame_num,frameSize,receiveSize,prf] = LinesperFile(Rx_sample_num,RxChannel,prf,seqNums);
% 
% NumsPerFile = TotalLines;
% File_nums = frame_num;



maxprf = floor(3.0/((Rx_sample_num*RxChannel*2+32)/1024/1024/1024)/2)*2;
if(prf>maxprf)
    disp("The prf you selected = " + prf + " has exceeded the limit")
    prf = maxprf;
    disp("automatically adjust to max prf = "+num2str(prf))
end







 % seqNums = frames*size(AcqConfig.Tx.sequence,2);
% [TotalLines,frame_num,frameSize,receiveSize,prf] = LinesperFile(Rx_sample_num,RxChannel,prf,seqNums);

% NumsPerFile = TotalLines;
% File_nums = frame_num;
trigger_fs = prf;

% 3. 准备调用参数
param = struct( 'adc_fs', AcqConfig.Tx.fs,...
    'sample_num', Rx_sample_num,...
    'frame_num_in_callback', 1,...  %无效
    'sensor_num', TxChannel,...
    'trigger_fs', trigger_fs,...
    'trigger_mode', 1,...     %   设置DAQ为内触发还是外触发，true为内触发，false为外触发
    'enable_2_network', 0,...
    'enable_upload', 6,...
    'extra_port_num', 0,...
    'merge_channel_num', 0,...
    'trigger_shield', 0,...
    'trigger_delay1', trigger_delay,...
    'trigger_delay2', trigger_delay,...
    'trigger_delay3', trigger_delay,...
    'tgc_gain1', 0,...
    'tgc_gain2', 0,...
    'tgc_gain3', 0,...
    'vca_gain1', 0,...
    'vca_gain2', 0,...
    'vca_gain3', 0);

% 4. 调用函数
if(RxChannel==128)
    result = calllib('DAQ_SDK', 'setDAQ', param, 1);
else
    result = calllib('DAQ_SDK', 'setDAQ', param, 3);

end
if result==0
    disp("set DAQ ok");
else
    % unloadlibrary('DAQ_SDK');
    if libisloaded('DAQ_SDK')
        calllib('DAQ_SDK', 'stop_sample');
        calllib('DAQ_SDK', 'close_sample');
        deleteDaq = calllib('DAQ_SDK', 'deleteDAQHandle');
        pause(1)
        % 卸载库
        unloadlibrary('DAQ_SDK');
    end
   
    NumsPerFile = -1;
    File_nums = -1;
    frameN =-1;

    disp("set DAQ failed");
    return;
end



% %采集设置，param1：单次接收数据总量(不带头):，param2:单次接收数据总量(带头)

% 5. 采集设置
% 原始数据长度
ADC_Data_len = length(ScanList) *(2 * Rx_sample_num*TxChannel+32) ;
data_empty = zeros(ADC_Data_len, 1, 'int8');
ADC_Data_Ptr = libpointer('int8Ptr', data_empty);

% param1：单次接收数据总量(不带头):，param2:单次接收数据总量(带头)
frame_num_pack = prf/25; % 每次打包的数量
if(round(frame_num_pack/length(ScanList))<1)
    frame_num_pack = length(ScanList);
else

    frame_num_pack = round(frame_num_pack/length(ScanList))*length(ScanList);
end

 

frameSize = frame_num_pack*2*Rx_sample_num*TxChannel;
receiveSize = frame_num_pack*(2*Rx_sample_num*TxChannel+32);
NumsPerFile = frame_num_pack;
% 开始采集
calllib("DAQ_SDK",'start_sample',frameSize, receiveSize);
disp("Start_sample ok");
disp("扫查中......")
% 根据framid控制停止
frameid = 0;
max_frameid = lasting_time*prf;
frameN = ceil(max_frameid/length(ScanList));
max_frameid = frameN*length(ScanList);
% File_nums = max_frameid;
File_nums = max_frameid;


while(frameid <= max_frameid+10)


    % 调用一次会从frame_num打包的数据取一帧，这帧数据拷贝到BData, 并返回frameid
    frameid=calllib("DAQ_SDK",'getOneFrameData', ADC_Data_Ptr);
    pause(0.001);

    if(frameid == -1) % 取数据失败
        continue;
    end
    fprintf("current_frame_id: %d\n",frameid);

end


calllib('DAQ_SDK', 'stop_sample');
calllib('DAQ_SDK', 'close_sample');
calllib('DAQ_SDK', 'deleteDAQHandle');
pause(1)
% 卸载库
if libisloaded('DAQ_SDK')
    unloadlibrary('DAQ_SDK');
    disp('库已成功卸载');
end



end


